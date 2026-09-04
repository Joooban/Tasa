import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'database_service.dart';

/// User-triggered export/import to a file via the native file picker — independent
/// of the DB's own migration safety net, this is the user's own insurance against
/// uninstalls, device loss, or resets.
class BackupService {
  final DatabaseService db;
  BackupService(this.db);

  String _defaultFileName() {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'tasa-backup-$stamp.json';
  }

  /// Returns the saved location, or null if the user cancelled the picker.
  Future<Uri?> exportToFile() async {
    final json = await db.exportAsJson();
    final bytes = Uint8List.fromList(utf8.encode(json));
    return FilePicker.saveFile(
      dialogTitle: 'Save Tasa backup',
      fileName: _defaultFileName(),
      bytes: bytes,
      mimeType: 'application/json',
    );
  }

  /// Returns true if a backup was picked and imported, false if the user cancelled.
  /// Throws a [FormatException] if the picked file wasn't a valid Tasa backup.
  Future<bool> importFromFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose a Tasa backup',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return false;

    final bytes = await file.readAsBytes();
    await db.importFromJson(utf8.decode(bytes));
    return true;
  }
}
