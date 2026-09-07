import 'dart:ui';

import 'package:flame/components.dart';

import 'iso_map_data.dart';

/// 格子高亮層：把指定的格子染成半透明色塊。
///
/// 三個功能共用同一層，而不是各畫各的：
/// - 放置預覽：家具將佔用的格子染綠（可放）或紅（不可放）
/// - 搬動家具：家具目前佔用的格子染藍
/// - GM 碰撞編輯：地形不可通行的格子染紅
///
/// 座標一律吃**陣列索引**（與 [IsoObjectComponent] 一致），
/// 呼叫端負責用 [IsoMapData.toIndex] 轉換 —— 兩個座標空間的交界只有這一處。
class TileOverlayLayer extends PositionComponent {
  TileOverlayLayer({required this.mapData}) {
    // 蓋在地板之上、所有物件之下。物件的 priority 是 layer*kLayerStride + y，
    // 最小的 layer 是 0，故取一個小的正數即可穩定壓在物件底下。
    priority = 1;
  }

  final IsoMapData mapData;

  /// key = (陣列索引 tx, ty)，value = 該格顏色。
  final Map<(int, int), Color> _cells = {};

  /// 可放置（綠）。
  static const okColor = Color(0x5500C853);

  /// 不可放置（紅）。
  static const blockedColor = Color(0x55D32F2F);

  /// 搬動中的家具原位置（藍）。
  static const movingColor = Color(0x552196F3);

  /// 地形碰撞（GM 編輯模式，較深的紅）。
  static const terrainColor = Color(0x66B71C1C);

  bool get isEmpty => _cells.isEmpty;

  /// 整批替換要高亮的格子。傳空 Map 等同 [clear]。
  void show(Map<(int, int), Color> cells) {
    _cells
      ..clear()
      ..addAll(cells);
  }

  /// 以單一顏色高亮一組格子。
  void showAll(Iterable<(int, int)> cells, Color color) {
    _cells
      ..clear()
      ..addEntries(cells.map((c) => MapEntry(c, color)));
  }

  void clear() => _cells.clear();

  @override
  void render(Canvas canvas) {
    if (_cells.isEmpty) return;

    final halfW = mapData.halfTileWidth;
    final halfH = mapData.halfTileHeight;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final entry in _cells.entries) {
      final (tx, ty) = entry.key;
      // 菱形四頂點：上、右、下、左（與 DrawPng 的 overlay_grid.py 的畫法一致）
      final top = mapData.tileToScreen(tx, ty);
      final path = Path()
        ..moveTo(top.x, top.y)
        ..lineTo(top.x + halfW, top.y + halfH)
        ..lineTo(top.x, top.y + halfH * 2)
        ..lineTo(top.x - halfW, top.y + halfH)
        ..close();
      paint.color = entry.value;
      canvas.drawPath(path, paint);
    }
  }
}
