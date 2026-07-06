import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_log.dart';
import 'iso_coord.dart';
import 'iso_map_data.dart';
import 'iso_tile_palette.dart';
import 'scene_asset_loader.dart';
import 'iso_map_loader.dart';
import 'iso_player_component.dart';

/// 等距地圖渲染元件。
///
/// position 的含義：tile (0,0) 頂點在父元件中的位置（anchor = topLeft）。
/// 採用 topLeft 使 local 座標系與渲染／`event.localPosition`／`screenToTile`
/// 完全一致（`localRender = 螢幕點 - position`），點擊座標不受 anchor 偏移影響。
/// 點擊地圖 tile 時，角色會走向被點擊的格子。
class IsoMapComponent extends PositionComponent with TapCallbacks {
  IsoMapComponent({
    required this.mapId,
    required this.spawnTileX,
    required this.spawnTileY,
    this.appearanceKey = 'male',
    this.onPlayerStep,
    this.onPlayerFace,
  }) : super(anchor: Anchor.topLeft);

  final int mapId;
  final int spawnTileX;
  final int spawnTileY;

  /// 人物外觀鍵（對應 character_sprites.json 的 sheet key）。
  final String appearanceKey;

  /// 每走一格回呼：(x, y, facing)，由 WorldSceneComponent 注入以送出 C_MOVE。
  final void Function(int x, int y, int facing)? onPlayerStep;

  /// 僅轉向回呼：(facing)，由 WorldSceneComponent 注入以送出 C_FACE。
  final void Function(int facing)? onPlayerFace;

  IsoMapData? _data;
  final Map<String, ui.Image> _images = {};
  ui.Image? _bgImage;
  IsoPlayerComponent? _player;

  /// 玩家在地圖 local 座標系的位置（供 WorldSceneComponent 做跟隨計算）。
  Vector2? get playerLocalPosition => _player?.position;

  /// 地圖內容 bounding box 在 local 座標系的中心（供整張置中用）。
  Vector2? get contentCenterLocal {
    final data = _data;
    if (data == null) return null;
    final bg = _bgImage;
    if (bg != null) {
      return Vector2(
        data.originX + bg.width / 2,
        data.originY + bg.height / 2,
      );
    }
    final halfW = data.halfTileWidth;
    final halfH = data.halfTileHeight;
    final minX = -(data.height - 1) * halfW - halfW;
    final maxX = (data.width - 1) * halfW + halfW;
    final maxY = (data.width - 1 + data.height - 1) * halfH + 2 * halfH;
    return Vector2((minX + maxX) / 2, maxY / 2);
  }

  // fallback 顏色（tileId 1~8）見 IsoTilePalette。
  static const _tileShadowColor = Color(0x33000000);
  static const _tileStrokeColor = Color(0x55000000);

  @override
  Future<void> onLoad() async {
    _data = await IsoMapLoader.load(mapId);
    final data = _data!;

    // 設定 hit box 大小讓 TapCallbacks 能正確偵測點擊
    final mapW = (data.width + data.height - 2) * data.halfTileWidth + data.tileWidth;
    final mapH = (data.width + data.height - 2) * data.halfTileHeight + data.tileHeight;
    size = Vector2(mapW, mapH);

    // 背景圖模式：載入整張房間圖，hitbox 改以圖片範圍計算。
    if (data.hasBackground) {
      _bgImage = await SceneAssetLoader.loadTileAtlas(data.background);
      final bg = _bgImage;
      if (bg != null) {
        size = Vector2(
          data.originX + bg.width.toDouble(),
          data.originY + bg.height.toDouble(),
        );
      }
    }

    for (final ts in data.tilesets) {
      if (ts.image.isEmpty) continue;
      final img = await SceneAssetLoader.loadTileAtlas(ts.image);
      if (img != null) {
        _images[ts.image] = img;
      }
    }

    // 載入人物 sprite（缺圖回 null → 玩家用 canvas fallback）。
    final spriteSet =
        await SceneAssetLoader.loadCharacterSprites(appearanceKey);

    _player = IsoPlayerComponent(
      initialTileX: spawnTileX.clamp(0, data.width - 1),
      initialTileY: spawnTileY.clamp(0, data.height - 1),
      mapData: data,
      onStep: onPlayerStep,
      onFace: onPlayerFace,
      spriteSet: spriteSet,
    );
    add(_player!);
  }

  // ── 點擊移動 ───────────────────────────────────────────────

  /// 地圖是整個世界唯一可點的地面，接受畫面內所有點擊；
  /// 落在菱形外的座標由 onTapDown 的 tx/ty 範圍檢查擋掉。
  /// （預設 containsLocalPoint 只認 local 0..size，會漏掉延伸到負 X 的左半部 tile。）
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapDown(TapDownEvent event) {
    // ── 診斷用（由 app_config.json log.tags."ISO-TAP" 控制是否輸出）──
    AppLog.d('ISO-TAP',
        'onTapDown local=${event.localPosition} '
        'shift=${HardwareKeyboard.instance.isShiftPressed}');
    final data = _data;
    final player = _player;
    if (data == null || player == null) return;

    final (tx, ty) = IsoCoord.screenToTile(
        event.localPosition, data.halfTileWidth, data.halfTileHeight);

    AppLog.d('ISO-TAP',
        'tile=($tx,$ty) player=(${player.tileX},${player.tileY}) '
        'inRange=${tx >= 0 && tx < data.width && ty >= 0 && ty < data.height}');

    if (tx < 0 || tx >= data.width || ty < 0 || ty >= data.height) return;

    if (HardwareKeyboard.instance.isShiftPressed) {
      // Shift+Click：僅轉向，不移動
      final dx = (tx - player.tileX).clamp(-1, 1);
      final dy = (ty - player.tileY).clamp(-1, 1);
      if (dx != 0 || dy != 0) {
        player.setFacing(IsoPlayerComponent.facingFromDelta(dx, dy));
      }
    } else {
      player.moveTo(tx, ty);
    }
  }

  // ── 地圖渲染 ───────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    final data = _data;
    if (data == null) return;

    // 背景圖（房間手繪圖）先鋪，tile 層再疊上。
    final bg = _bgImage;
    if (bg != null) {
      canvas.drawImage(bg, Offset(data.originX, data.originY), Paint());
    }

    final halfW = data.halfTileWidth;
    final halfH = data.halfTileHeight;

    for (final layer in data.layers) {
      _renderLayer(canvas, layer, data, halfW, halfH);
    }
  }

  void _renderLayer(Canvas canvas, IsoTileLayer layer, IsoMapData data,
      double halfW, double halfH) {
    for (int ty = 0; ty < data.height; ty++) {
      for (int tx = 0; tx < data.width; tx++) {
        final tileId = layer.tileAt(tx, ty);
        if (tileId <= 0) continue;

        final sp = IsoCoord.tileToScreen(tx, ty, halfW, halfH);

        final ts = _findTileset(tileId, data);
        if (ts != null && _images.containsKey(ts.image)) {
          _drawSpriteTile(canvas, ts, tileId, sp.x, sp.y, halfW, halfH);
        } else {
          _drawFallbackTile(canvas, sp.x, sp.y, halfW, halfH, tileId);
        }
      }
    }
  }

  IsoTileset? _findTileset(int tileId, IsoMapData data) {
    IsoTileset? result;
    for (final ts in data.tilesets) {
      if (ts.firstId <= tileId) result = ts;
    }
    return result;
  }

  void _drawSpriteTile(Canvas canvas, IsoTileset ts, int tileId,
      double topX, double topY, double halfW, double halfH) {
    final img = _images[ts.image]!;
    final localId = tileId - ts.firstId;
    final col = localId % ts.columns;
    final row = localId ~/ ts.columns;
    final src = Rect.fromLTWH(
      col * ts.tileWidth.toDouble(),
      row * ts.tileHeight.toDouble(),
      ts.tileWidth.toDouble(),
      ts.tileHeight.toDouble(),
    );
    final dst = Rect.fromLTWH(topX - halfW, topY, halfW * 2, halfH * 2);
    canvas.drawImageRect(img, src, dst, Paint());
  }

  void _drawFallbackTile(Canvas canvas, double topX, double topY,
      double halfW, double halfH, int tileId) {
    final baseColor = IsoTilePalette.colorFor(tileId);

    final topFace = Path()
      ..moveTo(topX, topY)
      ..lineTo(topX + halfW, topY + halfH)
      ..lineTo(topX, topY + halfH * 2)
      ..lineTo(topX - halfW, topY + halfH)
      ..close();

    // 左側面
    canvas.drawPath(
      Path()
        ..moveTo(topX - halfW, topY + halfH)
        ..lineTo(topX, topY + halfH * 2)
        ..lineTo(topX, topY + halfH * 2 + 4)
        ..lineTo(topX - halfW, topY + halfH + 4)
        ..close(),
      Paint()..color = Color.lerp(baseColor, Colors.black, 0.25)!,
    );

    // 右側面
    canvas.drawPath(
      Path()
        ..moveTo(topX + halfW, topY + halfH)
        ..lineTo(topX, topY + halfH * 2)
        ..lineTo(topX, topY + halfH * 2 + 4)
        ..lineTo(topX + halfW, topY + halfH + 4)
        ..close(),
      Paint()..color = Color.lerp(baseColor, Colors.black, 0.40)!,
    );

    // 頂面
    canvas.drawPath(topFace, Paint()..color = baseColor);

    // 左半暗角
    canvas.drawPath(
      Path()
        ..moveTo(topX, topY)
        ..lineTo(topX - halfW, topY + halfH)
        ..lineTo(topX, topY + halfH * 2)
        ..close(),
      Paint()..color = _tileShadowColor,
    );

    // 邊框
    canvas.drawPath(
      topFace,
      Paint()
        ..color = _tileStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }
}
