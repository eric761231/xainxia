import 'package:flutter/material.dart';

import 'map_editor/editor_screen.dart';

/// 地圖編輯器獨立入口（不進正式遊戲）。
///
/// 啟動：flutter run -d windows -t lib/tools/map_editor_main.dart
void main() {
  runApp(const MapEditorApp());
}

class MapEditorApp extends StatelessWidget {
  const MapEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '地圖編輯器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const EditorScreen(),
    );
  }
}
