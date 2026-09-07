import 'package:flame/components.dart';
import 'package:flutter/material.dart';

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
    this.opacity = 1.0,
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

  /// 繪製透明度；1=不透明。放置／搬動預覽的「幽靈」以 0.5 呈現。
  ///
  /// 可變是因為搬動時同一個元件要在「正常」與「半透明」之間切換，
  /// 重建元件會連帶重跑 onLoad 與圖片載入，沒有必要。
  double opacity;

  IsoFootprintShadowComponent? _shadowComponent;

  @override
  Future<void> onLoad() async {
    // 腳底＝所在格中心（= tile 頂點 + 半格高），與 player `_tileCenter` 一致。
    final top = mapData.tileToScreen(tileX, tileY);
    position = top + Vector2(0, mapData.halfTileHeight);
    // 依圖層分層 + 腳底深度。玩家會每幀以自身 y（含 characterLayer）更新 priority 與之交錯。
    priority = layer * kLayerStride + position.y.round() + zBias;
    // 陰影是獨立 sibling：在地面之上，但刻意低於全部玩家／物件本體。
    // 因而不論玩家位在家具前或後，接地陰影都不會蓋住玩家。
    if (def.shadow.enabled && def.shadow.opacity > 0) {
      final shadow = IsoFootprintShadowComponent(
        def: def,
        mapData: mapData,
        position: position.clone(),
        opacity: opacity,
        layer: layer,
      );
      _shadowComponent = shadow;
      await parent?.add(shadow);
    }
  }

  @override
  void onRemove() {
    _shadowComponent?.removeFromParent();
    _shadowComponent = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final g = graphic;
    if (g != null) {
      // 錨點依 anchorMode/明確 anchor 解析（以圖形 intrinsic 尺寸為基準）。
      final w0 = g.width, h0 = g.height;
      final (ax0, ay0) = def.resolveAnchor(
        w0,
        h0,
        mapHalfTileHeight: mapData.halfTileHeight,
      );
      // 尺寸覆寫：目標寬 = tilesW×格寬，等比縮放（錨點同步縮放）。
      final s = tilesW > 0 && w0 > 0 ? tilesW * mapData.tileWidth / w0 : 1.0;
      final w = w0 * s, h = h0 * s, ax = ax0 * s, ay = ay0 * s;
      // 錨點(ax,ay) 對齊 position(0,0) 後再加逐物件微調 (offsetX,offsetY)。
      g.paint(
        canvas,
        Rect.fromLTWH(-ax + offsetX, -ay + offsetY, w, h),
        opacity: opacity,
      );
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

/// 物件本體的獨立接地陰影層。它永遠在地面之上、角色和家具本體之下。
class IsoFootprintShadowComponent extends PositionComponent {
  IsoFootprintShadowComponent({
    required this.def,
    required this.mapData,
    required Vector2 position,
    required this.opacity,
    required int layer,
  }) : super(
         anchor: Anchor.topLeft,
         position: position,
         size: Vector2.zero(),
         priority: layer * kLayerStride - 1,
       );

  final ObjectDef def;
  final IsoMapData mapData;
  final double opacity;

  @override
  void render(Canvas canvas) {
    final shadow = def.shadow;
    if (!shadow.enabled || shadow.opacity <= 0 || opacity <= 0) return;

    final halfW = mapData.halfTileWidth;
    final halfH = mapData.halfTileHeight;
    final offset = Offset(
      shadow.offsetTilesX * mapData.tileWidth,
      shadow.offsetTilesY * mapData.tileHeight,
    );
    final path = Path();
    for (var y = 0; y < def.footprintH; y++) {
      for (var x = 0; x < def.footprintW; x++) {
        // 物件 anchor 是 footprint 的右前角；這與 Map collision stamp 的
        // tileX-x / tileY-y 定義一致。
        final top = mapData.tileToScreen(-x, -y);
        final centerY = top.y + halfH;
        path.addPolygon([
          Offset(top.x, centerY - halfH) + offset,
          Offset(top.x + halfW, centerY) + offset,
          Offset(top.x, centerY + halfH) + offset,
          Offset(top.x - halfW, centerY) + offset,
        ], true);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(
          20,
          14,
          12,
          (shadow.opacity * opacity).clamp(0.0, 1.0).toDouble(),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blur),
    );
  }
}
