import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Real OS share sheet — the native build's replacement for the prototype's
/// clipboard/`navigator.share` fallback. Wrapped renders as an actual shareable
/// image captured from the on-screen card.
class ShareService {
  Future<void> shareWrappedCard({
    required GlobalKey boundaryKey,
    required String fallbackText,
  }) async {
    final bytes = await _captureBoundary(boundaryKey);
    if (bytes == null) {
      await SharePlus.instance.share(
        ShareParams(text: fallbackText, subject: 'My Tasa Wrapped'),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'tasa-wrapped-${DateTime.now().microsecondsSinceEpoch}.png');
    final file = File(path);
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: fallbackText, subject: 'My Tasa Wrapped'),
    );
  }

  Future<Uint8List?> _captureBoundary(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
