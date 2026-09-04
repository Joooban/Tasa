import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/date_utils.dart';
import '../logic/sample_data.dart';
import '../logic/streak.dart';
import '../models/entry.dart';
import '../models/profile.dart';
import 'services_providers.dart';

/// Everything the app reasons about, loaded once from the DB — mirrors the
/// prototype's single `state` blob so the mental model carries over 1:1.
class CupboardState {
  final List<Entry> entries;
  final Profile profile;
  final BeanProfile beanProfile;
  final AppSettings settings;
  final List<DateTime> freezeDates;
  final List<String> toastQueue;

  const CupboardState({
    required this.entries,
    required this.profile,
    required this.beanProfile,
    required this.settings,
    required this.freezeDates,
    this.toastQueue = const [],
  });

  CupboardState copyWith({
    List<Entry>? entries,
    Profile? profile,
    BeanProfile? beanProfile,
    AppSettings? settings,
    List<DateTime>? freezeDates,
    List<String>? toastQueue,
  }) {
    return CupboardState(
      entries: entries ?? this.entries,
      profile: profile ?? this.profile,
      beanProfile: beanProfile ?? this.beanProfile,
      settings: settings ?? this.settings,
      freezeDates: freezeDates ?? this.freezeDates,
      toastQueue: toastQueue ?? this.toastQueue,
    );
  }

  List<Entry> get realEntries => entries.where((e) => e.kind != EntryKind.skip).toList();
}

class CupboardController extends AsyncNotifier<CupboardState> {
  @override
  Future<CupboardState> build() async {
    final db = ref.watch(databaseServiceProvider);
    var entries = await db.getAllEntries();
    if (entries.isEmpty) {
      final samples = sampleEntries();
      await db.insertEntries(samples);
      entries = samples;
    }

    final profile = await db.getProfile();
    final beanProfile = await db.getBeanProfile();
    var settings = await db.getAppSettings();
    var freezeDates = await db.getFreezeDates();

    // Deleting an entry (or swapping its photo on edit) never removes the old
    // file immediately, so an in-progress "Undo" snackbar still has something
    // to restore. Sweep anything now-unreferenced on the next cold start instead.
    final referencedPhotos = entries.map((e) => e.photoPath).whereType<String>().toSet();
    unawaited(ref.read(imageServiceProvider).pruneOrphanedPhotos(referencedPhotos));

    final reconciled = reconcileRainChecks(
      entries: entries,
      settings: settings,
      freezeDates: freezeDates,
    );
    final toasts = <String>[];
    if (reconciled.changed) {
      settings = reconciled.settings;
      freezeDates = reconciled.freezeDates;
      await db.saveAppSettings(settings);
      await db.saveFreezeDates(freezeDates);
      for (final d in reconciled.newlyConsumedDates) {
        toasts.add('Used a rain check for ${_fmt(d)} — streak stayed alive.');
      }
      if (reconciled.milestonesAwarded > 0) {
        toasts.add('Rain check earned — ${settings.freezeBank} saved up.');
      }
    }

    return CupboardState(
      entries: entries,
      profile: profile,
      beanProfile: beanProfile,
      settings: settings,
      freezeDates: freezeDates,
      toastQueue: toasts,
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}';

  CupboardState get _current => state.requireValue;

  void _pushToast(String message) {
    state = AsyncData(_current.copyWith(toastQueue: [..._current.toastQueue, message]));
  }

  void consumeToast(String message) {
    if (!state.hasValue) return;
    final remaining = List<String>.from(_current.toastQueue)..remove(message);
    state = AsyncData(_current.copyWith(toastQueue: remaining));
  }

  Future<void> saveEntry(Entry entry, {required bool isNew}) async {
    final db = ref.read(databaseServiceProvider);
    await db.upsertEntry(entry);
    final entries = List<Entry>.from(_current.entries);
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx > -1) {
      entries[idx] = entry;
    } else {
      entries.add(entry);
    }
    state = AsyncData(_current.copyWith(entries: entries));
    if (isNew) await _maybeClearSampleAfterRealEntry();
  }

  Future<Entry?> deleteEntry(String id) async {
    final entries = _current.entries;
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return null;
    final removed = entries[idx];
    final db = ref.read(databaseServiceProvider);
    await db.deleteEntry(id);
    final updated = List<Entry>.from(entries)..removeAt(idx);
    state = AsyncData(_current.copyWith(entries: updated));
    return removed;
  }

  Future<void> restoreEntry(Entry entry) async {
    final db = ref.read(databaseServiceProvider);
    await db.upsertEntry(entry);
    state = AsyncData(_current.copyWith(entries: [..._current.entries, entry]));
  }

  Future<String> repeatYesterday() async {
    final yesterday = offsetDate(todayDate(), -1);
    final candidates = _current.entries
        .where((e) => e.kind != EntryKind.skip && isSameDate(e.date, yesterday))
        .toList();
    if (candidates.isEmpty) return 'No cup logged yesterday to repeat.';
    final src = candidates.last;
    final copy = src.copyWith(
      id: Entry.newId(),
      date: todayDate(),
      isSample: false,
    );
    await saveEntry(copy, isNew: true);
    return 'Logged — same as yesterday.';
  }

  Future<String> skipToday() async {
    final today = todayDate();
    final alreadyLogged = _current.entries.any((e) => isSameDate(e.date, today));
    if (alreadyLogged) return "Today's already logged.";
    final entry = Entry.skip(date: today);
    final db = ref.read(databaseServiceProvider);
    await db.upsertEntry(entry);
    state = AsyncData(_current.copyWith(entries: [..._current.entries, entry]));
    return 'No coffee today — streak kept.';
  }

  Future<void> _maybeClearSampleAfterRealEntry() async {
    if (_current.settings.seenRealEntry) return;
    final settings = _current.settings.copyWith(seenRealEntry: true);
    final db = ref.read(databaseServiceProvider);
    final hadSamples = _current.entries.any((e) => e.isSample);
    if (hadSamples) {
      await db.deleteSampleEntries();
      final updated = _current.entries.where((e) => !e.isSample).toList();
      state = AsyncData(_current.copyWith(entries: updated, settings: settings));
      _pushToast('Sample cups cleared — this is your cupboard now.');
    } else {
      state = AsyncData(_current.copyWith(settings: settings));
    }
    await db.saveAppSettings(settings);
  }

  Future<String> clearSampleEntries() async {
    final had = _current.entries.any((e) => e.isSample);
    final db = ref.read(databaseServiceProvider);
    await db.deleteSampleEntries();
    final updated = _current.entries.where((e) => !e.isSample).toList();
    state = AsyncData(_current.copyWith(entries: updated));
    return had ? 'Sample cups cleared.' : 'No sample cups to clear.';
  }

  Future<void> saveProfileName(String name) async {
    final profile = Profile(name: name.trim().substring(0, name.trim().length.clamp(0, 24)));
    final db = ref.read(databaseServiceProvider);
    await db.saveProfile(profile);
    state = AsyncData(_current.copyWith(profile: profile));
  }

  Future<void> saveBeanProfile({required double bagPrice, required int cupsPerBag}) async {
    final beanProfile = BeanProfile(bagPrice: bagPrice, cupsPerBag: cupsPerBag);
    final db = ref.read(databaseServiceProvider);
    await db.saveBeanProfile(beanProfile);
    state = AsyncData(_current.copyWith(beanProfile: beanProfile));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final settings = _current.settings.copyWith(themeMode: mode);
    final db = ref.read(databaseServiceProvider);
    await db.saveAppSettings(settings);
    state = AsyncData(_current.copyWith(settings: settings));
  }

  Future<void> setHideAmount(bool hide) async {
    final settings = _current.settings.copyWith(hideAmount: hide);
    final db = ref.read(databaseServiceProvider);
    await db.saveAppSettings(settings);
    state = AsyncData(_current.copyWith(settings: settings));
  }

  Future<void> completeOnboarding({String? name}) async {
    final db = ref.read(databaseServiceProvider);
    var next = _current;
    if (name != null && name.trim().isNotEmpty) {
      final profile = Profile(name: name.trim().substring(0, name.trim().length.clamp(0, 24)));
      await db.saveProfile(profile);
      next = next.copyWith(profile: profile);
    }
    final settings = next.settings.copyWith(hasOnboarded: true);
    await db.saveAppSettings(settings);
    state = AsyncData(next.copyWith(settings: settings));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final settings = _current.settings.copyWith(notificationsEnabled: enabled);
    final db = ref.read(databaseServiceProvider);
    await db.saveAppSettings(settings);
    state = AsyncData(_current.copyWith(settings: settings));
  }

  /// Wipes and replaces everything from a validated backup, then reloads.
  Future<void> reloadFromDatabase() async {
    ref.invalidateSelf();
    await future;
  }
}

final cupboardControllerProvider =
    AsyncNotifierProvider<CupboardController, CupboardState>(CupboardController.new);
