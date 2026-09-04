import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Camera/gallery access + compression. Runtime permission is requested by
/// image_picker itself at the moment a photo is added, not upfront — a denial
/// simply returns null here and logging continues without a photo.
class ImageService {
  final _picker = ImagePicker();

  /// Returns null on cancellation *or* on any picker/permission failure —
  /// a denied camera/gallery permission degrades to "no photo" rather than
  /// crashing or surfacing a scary error for what's an optional field.
  Future<String?> pickAndCompress({required ImageSource source}) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
    } catch (_) {
      return null;
    }
    if (picked == null) return null;
    try {
      return await _compressAndStore(File(picked.path));
    } catch (_) {
      return null;
    }
  }

  /// Resizes to a max dimension and re-encodes as JPEG on save (not on read) —
  /// native storage isn't capped like localStorage, but uncompressed photos
  /// accumulated daily over months would still bloat the app and slow the feed.
  Future<String> _compressAndStore(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);

    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final targetPath = p.join(photosDir.path, fileName);

    final result = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 960,
      minHeight: 960,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      // Compression failed (unsupported format, etc.) — fall back to the
      // picker's own already-downscaled copy rather than losing the photo.
      final fallback = File(targetPath);
      await source.copy(fallback.path);
      return fallback.path;
    }
    return result.path;
  }

  Future<void> deletePhoto(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort — a leftover file here just costs a little storage.
    }
  }

  /// Deletes any file in the photos directory that no current entry points
  /// to. Run at startup rather than at delete-time so a just-deleted entry's
  /// photo survives long enough for its "Undo" snackbar to still work.
  Future<void> pruneOrphanedPhotos(Set<String> referencedPaths) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(dir.path, 'photos'));
      if (!await photosDir.exists()) return;
      final referencedNames = referencedPaths.map(p.basename).toSet();
      await for (final entity in photosDir.list()) {
        if (entity is! File) continue;
        if (!referencedNames.contains(p.basename(entity.path))) {
          try {
            await entity.delete();
          } catch (_) {
            // Best-effort — try the rest even if one file can't be removed.
          }
        }
      }
    } catch (_) {
      // Best-effort cleanup only — never let this block app startup.
    }
  }
}
