import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'char_create_ui_assets.dart';
import 'char_create_ui_spec.dart';

/// 登入成功過場：預載創角 XML + PNG。
abstract final class CharCreateUiPreloader {
  static bool _done = false;

  static bool get isDone => _done;

  /// [onProgress] 回報 0.0～1.0，供 Transition 進度條。
  static Future<void> preload({
    void Function(double progress)? onProgress,
  }) async {
    if (_done) {
      onProgress?.call(1.0);
      return;
    }

    void report(double value) {
      onProgress?.call(value.clamp(0.0, 1.0));
    }

    report(0.0);
    await CharCreateUiSpec.ensureLoaded();
    report(0.08);

    final paths = CharCreateUiAssets.allPreloadPaths;
    if (paths.isEmpty) {
      _done = true;
      report(1.0);
      return;
    }

    const xmlWeight = 0.08;
    final pngWeight = 1.0 - xmlWeight;

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      await _loadBytes(path);
      if (CharCreateUiAssets.decodeOnPreload.contains(path)) {
        await _decodeImage(path);
      }
      report(xmlWeight + pngWeight * (i + 1) / paths.length);
    }

    _done = true;
    report(1.0);
  }

  static Future<void> _loadBytes(String path) async {
    try {
      await rootBundle.load(path);
    } catch (e) {
      debugPrint('CharCreateUiPreloader skipped: $path ($e)');
    }
  }

  static Future<void> _decodeImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      await codec.getNextFrame();
      codec.dispose();
    } catch (e) {
      debugPrint('CharCreateUiPreloader decode skipped: $path ($e)');
    }
  }
}
