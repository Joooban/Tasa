import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';
import '../models/profile.dart';

/// Bump when the table shape changes, and add the migration to [_migrate].
/// Every schema change ships with an explicit migration — never a silent one.
const kDbSchemaVersion = 3;

const _dbFileName = 'tasa.db';

/// Owns the local SQLite database: schema, migrations, and CRUD. A real local DB
/// (vs. a JSON blob in localStorage) so schema changes can be versioned and a bad
/// migration can be rolled back from the pre-migration snapshot instead of
/// silently destroying someone's cupboard history.
class DatabaseService {
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<String> _dbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbFileName);
  }

  Future<Database> _open() async {
    final path = await _dbPath();
    await _backupBeforeMigrationIfNeeded(path);
    return openDatabase(
      path,
      version: kDbSchemaVersion,
      onCreate: (db, version) => _createAll(db),
      onUpgrade: (db, oldVersion, newVersion) => _migrate(db, oldVersion, newVersion),
    );
  }

  /// Snapshots the on-disk database file before letting sqflite run any migration,
  /// so a buggy migration can be rolled back by restoring the copy.
  Future<void> _backupBeforeMigrationIfNeeded(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    int onDiskVersion;
    try {
      final probe = await openDatabase(path, readOnly: true);
      onDiskVersion = await probe.getVersion();
      await probe.close();
    } catch (_) {
      return;
    }
    if (onDiskVersion >= kDbSchemaVersion) return;

    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final backupPath = p.join(
      backupDir.path,
      'tasa_pre_migration_v${onDiskVersion}_to_v${kDbSchemaVersion}_$stamp.db',
    );
    await file.copy(backupPath);
  }

  Future<void> _createAll(Database db) async {
    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        date TEXT NOT NULL,
        method TEXT,
        price REAL,
        free INTEGER NOT NULL DEFAULT 0,
        rating INTEGER NOT NULL DEFAULT 0,
        caption TEXT,
        notes TEXT,
        photo_path TEXT,
        time_of_day TEXT,
        flavors TEXT,
        roast TEXT,
        venue_tag TEXT,
        venue_name TEXT,
        is_sample INTEGER NOT NULL DEFAULT 0,
        schema_version INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_entries_date ON entries(date)');

    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE bean_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        bag_price REAL NOT NULL DEFAULT 450,
        cups_per_bag INTEGER NOT NULL DEFAULT 16
      )
    ''');
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        hide_amount INTEGER NOT NULL DEFAULT 0,
        seen_real_entry INTEGER NOT NULL DEFAULT 0,
        freeze_bank INTEGER NOT NULL DEFAULT 0,
        freeze_milestone INTEGER NOT NULL DEFAULT 0,
        notifications_enabled INTEGER NOT NULL DEFAULT 0,
        has_onboarded INTEGER NOT NULL DEFAULT 0,
        theme_mode TEXT NOT NULL DEFAULT 'system'
      )
    ''');
    await db.execute('''
      CREATE TABLE freeze_dates (
        date TEXT PRIMARY KEY
      )
    ''');

    await db.insert('profile', const Profile().toMap());
    await db.insert('bean_profile', const BeanProfile().toMap());
    await db.insert('app_settings', const AppSettings().toMap());
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE entries ADD COLUMN notes TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE app_settings ADD COLUMN theme_mode TEXT NOT NULL DEFAULT 'system'",
      );
    }
  }

  // ---------------- entries ----------------

  Future<List<Entry>> getAllEntries() async {
    final rows = await (await db).query('entries', orderBy: 'date DESC');
    return rows.map(Entry.fromMap).toList();
  }

  Future<void> upsertEntry(Entry entry) async {
    await (await db).insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteEntry(String id) async {
    await (await db).delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSampleEntries() async {
    await (await db).delete('entries', where: 'is_sample = 1');
  }

  Future<void> insertEntries(List<Entry> entries) async {
    final batch = (await db).batch();
    for (final e in entries) {
      batch.insert('entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ---------------- profile / bean profile / settings ----------------

  Future<Profile> getProfile() async {
    final rows = await (await db).query('profile', where: 'id = 1', limit: 1);
    return rows.isEmpty ? const Profile() : Profile.fromMap(rows.first);
  }

  Future<void> saveProfile(Profile profile) async {
    await (await db)
        .insert('profile', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<BeanProfile> getBeanProfile() async {
    final rows = await (await db).query('bean_profile', where: 'id = 1', limit: 1);
    return rows.isEmpty ? const BeanProfile() : BeanProfile.fromMap(rows.first);
  }

  Future<void> saveBeanProfile(BeanProfile beanProfile) async {
    await (await db).insert('bean_profile', beanProfile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AppSettings> getAppSettings() async {
    final rows = await (await db).query('app_settings', where: 'id = 1', limit: 1);
    return rows.isEmpty ? const AppSettings() : AppSettings.fromMap(rows.first);
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    await (await db).insert('app_settings', settings.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DateTime>> getFreezeDates() async {
    final rows = await (await db).query('freeze_dates');
    return rows.map((r) => DateTime.parse(r['date'] as String)).toList();
  }

  Future<void> saveFreezeDates(List<DateTime> dates) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('freeze_dates');
      final batch = txn.batch();
      for (final d in dates) {
        batch.insert('freeze_dates', {
          'date':
              '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  // ---------------- backup / restore ----------------

  /// Everything the user's insurance file needs — independent of the DB's own
  /// migration safety net.
  Future<Map<String, Object?>> exportAll() async {
    final entries = await getAllEntries();
    final profile = await getProfile();
    final beanProfile = await getBeanProfile();
    final settings = await getAppSettings();
    final freezeDates = await getFreezeDates();
    return {
      'schemaVersion': kDbSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => e.toMap()).toList(),
      'profile': profile.toMap(),
      'beanProfile': beanProfile.toMap(),
      'settings': settings.toMap(),
      'freezeDates': freezeDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  Future<void> importAll(Map<String, Object?> data) async {
    final rawEntries = data['entries'];
    if (rawEntries is! List) {
      throw const FormatException('Backup is missing an entries list.');
    }
    final entries = rawEntries
        .cast<Map<Object?, Object?>>()
        .map((m) => Entry.fromMap(m.cast<String, Object?>()))
        .toList();
    final profile = data['profile'] is Map
        ? Profile.fromMap((data['profile'] as Map).cast<String, Object?>())
        : const Profile();
    final beanProfile = data['beanProfile'] is Map
        ? BeanProfile.fromMap((data['beanProfile'] as Map).cast<String, Object?>())
        : const BeanProfile();
    final settings = data['settings'] is Map
        ? AppSettings.fromMap((data['settings'] as Map).cast<String, Object?>())
        : const AppSettings();
    final freezeDates = (data['freezeDates'] as List? ?? [])
        .map((s) => DateTime.parse(s as String))
        .toList();

    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('entries');
      final batch = txn.batch();
      for (final e in entries) {
        batch.insert('entries', e.toMap());
      }
      batch.insert('profile', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('bean_profile', beanProfile.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('app_settings', settings.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
      await txn.delete('freeze_dates');
      final freezeBatch = txn.batch();
      for (final d in freezeDates) {
        freezeBatch.insert('freeze_dates', {'date': d.toIso8601String().substring(0, 10)});
      }
      await freezeBatch.commit(noResult: true);
    });
  }

  Future<String> exportAsJson() async => jsonEncode(await exportAll());

  Future<void> importFromJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('That did not look like a valid backup.');
    }
    await importAll(decoded);
  }
}
