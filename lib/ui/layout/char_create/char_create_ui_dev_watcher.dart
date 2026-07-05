import 'dart:async';

import 'package:flutter/foundation.dart';

import 'char_create_ui_spec.dart';
import '../char_select/char_select_ui_spec.dart';
import 'char_create_ui_source_stub.dart'
    if (dart.library.io) 'char_create_ui_source_io.dart';
import '../ui_layout_xml_registry.dart';

/// Debug 模式下監聽 [UiLayoutXmlRegistry] 內所有 XML，存檔後自動 reload。
abstract final class CharCreateUiDevWatcher {
  static bool _started = false;

  static void ensureStarted() {
    if (!kDebugMode || _started) {
      return;
    }
    _started = true;
    for (final path in UiLayoutXmlRegistry.all) {
      watchDebugAssetFile(path, () {
        unawaited(CharCreateUiSpec.reload());
        unawaited(CharSelectUiSpec.reload());
      });
    }
    debugPrint(
      'CharCreateUiDevWatcher：已啟動 XML 即時預覽（${UiLayoutXmlRegistry.all.length} 個檔案）',
    );
  }
}
