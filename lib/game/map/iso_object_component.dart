import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'iso_coord.dart';
import 'iso_map_data.dart';
import 'iso_object_catalog.dart';
import 'iso_object_graphic.dart';

/// 圖層優先權間距：`priority = layer*kLayerStride + 腳底y`。
/// 需 > 任何地圖可能的腳底螢幕 y，確保低層恆在高層之下。
const int kLayerStride = 100000;

/// 地圖布置物件（prop）的渲染元件。
///
/// 站位：腳底錨點對齊所在格中心（與 [IsoPlayerComponent] 同一基準）。
/// 深度：`priority = 腳底螢幕 y + zBias`；玩家每幀也以自身 y 設 priority，
/// 於是 Flame 依 priority 自動 z 排序 → 玩家可走到物件前方或後方
/// （花在門前、樹在屋後）。
///
/// 缺圖時畫半透明色塊 fallback（無美術也能擺放與定位）。
class IsoObjectComponent extends PositionComponent {
  IsoObjectComponent({
    required this.def,
    required this.tileX,
    required this.tileY,
    required this.zBias,
    required this.mapData,
    required this.graphic,
    this.offsetX = 0,
    this.offsetY = 0,
    this.tilesW = 0,
    this.layer = 1,
  }) : super(anchor: Anchor.topLeft, size: Vector2.zero());

  final ObjectDef def;
  final int tileX;
  final int tileY;
  final int zBias;
  final IsoMapData mapData;

  /// 逐物件像素微調（相對錨點對齊格中心再位移）。
  final double offsetX;
  final double offsetY;

  /// 尺寸覆寫：目標寬＝tilesW×64px 等比縮放；0＝原尺寸。
  final int tilesW;

  /// 所在圖層（1＝最底層）；影響繪製優先權。
  final int layer;

  /// 物件圖形（點陣或 SVG 向量；null → fallback 色塊）。
  final ObjectGraphic? graphic;

  @override
  Future<void> onLoad() async {
    // 腳底＝所在格中心（= tile 頂點 + 半格高），與 player `_tileCenter` 一致。
    final top = IsoCoord.tileToScreen(
        tileX, tileY, mapData.halfTileWidth, mapData.halfTileHeight);
    position = top + Vector2(0, mapData.halfTileHeight);
    // 依圖層分層 + 腳底深度。玩家會每幀以自身 y（含 characterLayer）更新 priority 與之交錯。
    priority = layer * kLayerStride + position.y.round() + zBias;
  }

  @override
  void render(Canvas canvas) {
    final g = graphic;
    if (g != null) {
      // 錨點依 anchorMode/明確 anchor 解析（以圖形 intrinsic 尺寸為基準）。
      final w0 = g.width, h0 = g.height;
      final (ax0, ay0) =
          def.resolveAnchor(w0, h0, mapHalfTileHeight: mapData.halfTileHeight);
      // 尺寸覆寫：目標寬 = tilesW×格寬，等比縮放（錨點同步縮放）。
      final s = tilesW > 0 && w0 > 0 ? tilesW * mapData.tileWidth / w0 : 1.0;
      final w = w0 * s, h = h0 * s, ax = ax0 * s, ay = ay0 * s;
      // 錨點(ax,ay) 對齊 position(0,0) 後再加逐物件微調 (offsetX,offsetY)。
      g.paint(canvas, Rect.fromLTWH(-ax + offsetX, -ay + offsetY, w, h));
      return;
    }

    // fallback：以一格寬、約兩格高的色塊立在腳底，標出物件位置與 id。
    final w = mapData.halfTileWidth * 1.2;
    final h = mapData.tileHeight * 1.6;
    final rect = Rect.fromLTWH(-w / 2, -h, w, h);
    canvas.drawRect(rect, Paint()..color = const Color(0x9955C36B));
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xCC1E5631)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '${def.id}',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -h / 2 - tp.height / 2));
  }
}
