import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide PointerMoveEvent;
import 'package:flutter/services.dart';

import '../../config/app_log.dart';
import 'iso_coord.dart';
import 'iso_map_data.dart';
import 'interaction_indicator.dart';
import 'iso_object_catalog.dart';
import 'iso_object_component.dart';
import 'iso_object_graphic.dart';
import 'scene_asset_loader.dart';
import 'iso_player_component.dart';

/// 等距地圖渲染元件。
///
/// position 的含義：tile (0,0) 頂點在父元件中的位置（anchor = topLeft）。
/// 採用 topLeft 使 local 座標系與渲染／`event.localPosition`／`screenToTile`
/// 完全一致（`localRender = 螢幕點 - position`），點擊座標不受 anchor 偏移影響。
/// 點擊地圖 tile 時，角色會走向被點擊的格子。
class IsoMapComponent extends PositionComponent
    with TapCallbacks, PointerMoveCallbacks {
  IsoMapComponent({
    required this.mapId,
    required this.spawnTileX,
    required this.spawnTileY,
    this.spawnFacing = 2,
    this.appearanceKey = 'male',
    this.onPlayerStep,
    this.onPlayerFace,
    this.onInteract,
  }) : super(anchor: Anchor.topLeft);

  final int mapId;
  final int spawnTileX;
  final int spawnTileY;

  /// 出生面向（0-7）；由伺服器 S_MAP_CHANGE 的 facing 傳入，換圖後保留朝向。
  final int spawnFacing;

  /// 人物外觀鍵（對應 character_sprites.json 的 sheet key）。
  final String appearanceKey;

  /// 每走一格回呼：(x, y, facing)，由 WorldSceneComponent 注入以送出 C_MOVE。
  final void Function(int x, int y, int facing)? onPlayerStep;

  /// 僅轉向回呼：(facing)，由 WorldSceneComponent 注入以送出 C_FACE。
  final void Function(int facing)? onPlayerFace;

  /// 走到互動物件相鄰一格時觸發（採集／對話／攻擊）。
  final void Function(MapInteractable interactable)? onInteract;

  IsoMapData? _data;
  final Map<String, ui.Image> _images = {};
  ui.Image? _bgImage;
  IsoPlayerComponent? _player;

  /// 動畫時鐘（驅動互動指標的循環相位）。
  double _animClock = 0;

  /// 滑鼠/手指目前指著的互動物件（hover 顯示動畫指標）。
  MapInteractable? _hovered;

  /// 點擊後正在走近、待觸發的互動物件。
  MapInteractable? _pending;

  /// 玩家最後點擊(tap)的格；渲染時以半透明紅高亮（下次點擊更新）。
  (int, int)? _tappedCell;

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

  /// 玩家目前所在格 X（未載入時回 spawn）。供小地圖標記。
  int get playerTileX => _player?.tileX ?? spawnTileX;

  /// 玩家目前所在格 Y（未載入時回 spawn）。
  int get playerTileY => _player?.tileY ?? spawnTileY;

  /// 玩家目前面向 0-7（未載入時回 spawn 面向）。
  int get playerFacing => _player?.facing ?? spawnFacing;

  @override
  Future<void> onLoad() async {
    // 遊戲端統一底版：程式產生的通用灰格（零 PNG），尺寸對齊伺服器 map 表
    // （map.sql bounds 1..50 → 可走 (1,1)..(50,50) 共 50×50 格、中心 (25,25)）。
    // 地圖美術之後再鋪。
    _data = IsoMapData.generic();
    final data = _data!;

    // 整張地圖視覺等比縮放（Flame 於 render 前套用變換）。
    scale = Vector2.all(data.renderScale);

    // 設定 hit box 大小讓 TapCallbacks 能正確偵測點擊
    final mapW = (data.width + data.height - 2) * data.halfTileWidth + data.tileWidth;
    final mapH = (data.width + data.height - 2) * data.halfTileHeight + data.tileHeight;
    size = Vector2(mapW, mapH);

    // 背景圖模式：載入整張房間圖，hitbox 改以圖片範圍計算。
    if (data.hasBackground) {
      _bgImage = await SceneAssetLoader.loadSceneImage(data.background);
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

    // 布置物件（prop）：依 catalog 建元件並加入為子元件（與玩家一起深度排序），
    // blocking 物件的 footprint 格 stamp 進碰撞層 → mapData.isBlocked 生效。
    await _loadObjects(data);

    // 載入人物 sprite（缺圖回 null → 玩家用 canvas fallback）。
    final spriteSet =
        await SceneAssetLoader.loadCharacterSprites(appearanceKey);

    _player = IsoPlayerComponent(
      initialTileX: spawnTileX.clamp(0, data.width - 1),
      initialTileY: spawnTileY.clamp(0, data.height - 1),
      initialFacing: spawnFacing,
      mapData: data,
      // 換圖改由伺服器權威 portal 協定驅動：每走一格回報 (x,y,facing)，
      // 由 WorldSceneComponent 送 C_MOVE 並偵測是否踏入傳送點。
      onStep: (x, y, facing) => onPlayerStep?.call(x, y, facing),
      onFace: onPlayerFace,
      spriteSet: spriteSet,
    );
    add(_player!);
  }

  /// 依物件層 + catalog 建立每個 prop 元件，並把 blocking 物件 stamp 進碰撞層。
  Future<void> _loadObjects(IsoMapData data) async {
    if (data.objects.isEmpty) return;
    final catalog = await IsoObjectCatalog.load();

    List<List<int>>? collGrid; // 需要 stamp 時才建立/取得
    for (final obj in data.objects) {
      final def = catalog[obj.id];
      if (def == null) {
        AppLog.d('ISO-OBJ', '找不到物件定義 id=${obj.id}（略過）');
        continue;
      }
      final g = await ObjectGraphic.loadForDir(def.dir, def.image);
      add(IsoObjectComponent(
        def: def,
        tileX: obj.x,
        tileY: obj.y,
        zBias: obj.zBias,
        mapData: data,
        graphic: g,
        offsetX: obj.offsetX,
        offsetY: obj.offsetY,
        tilesW: obj.tilesW,
        layer: obj.layer,
      ));

      if (def.blocking) {
        collGrid ??= _ensureCollisionGrid(data);
        // footprint 由腳底(x,y)往「後」（螢幕上方＝x,y 遞減）延伸。
        for (var j = 0; j < def.footprintH; j++) {
          for (var i = 0; i < def.footprintW; i++) {
            final tx = obj.x - i;
            final ty = obj.y - j;
            if (tx >= 0 && tx < data.width && ty >= 0 && ty < data.height) {
              collGrid[ty][tx] = 1;
            }
          }
        }
      }
    }
  }

  /// 取得（或建立）碰撞層的 grid，供物件 footprint stamp。
  /// 建立的碰撞層只存在於執行期記憶體，不影響存檔。
  List<List<int>> _ensureCollisionGrid(IsoMapData data) {
    final existing = data.collisionLayer;
    if (existing != null) return existing.data;
    final grid = List.generate(
      data.height,
      (_) => List<int>.filled(data.width, 0),
    );
    data.layers.add(
      IsoTileLayer(name: 'collision', type: 'collision', data: grid),
    );
    return grid;
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

    // 記錄點擊格 → 渲染時該格顯示半透明紅。
    _tappedCell = (tx, ty);

    if (HardwareKeyboard.instance.isShiftPressed) {
      // Shift+Click：僅轉向，不移動
      final dx = (tx - player.tileX).clamp(-1, 1);
      final dy = (ty - player.tileY).clamp(-1, 1);
      if (dx != 0 || dy != 0) {
        player.setFacing(IsoPlayerComponent.facingFromDelta(dx, dy));
      }
      return;
    }

    // 點到互動物件 → 走近至相鄰一格再觸發；否則一般移動。
    final it = data.interactableAt(tx, ty);
    if (it != null) {
      _beginInteraction(it);
    } else {
      player.moveTo(tx, ty);
    }
  }

  // ── 互動框架（hover → 走近 → 觸發）─────────────────────────

  @override
  void onPointerMove(PointerMoveEvent event) {
    final data = _data;
    if (data == null) return;
    final (tx, ty) = IsoCoord.screenToTile(
        event.localPosition, data.halfTileWidth, data.halfTileHeight);
    _hovered = (tx >= 0 && tx < data.width && ty >= 0 && ty < data.height)
        ? data.interactableAt(tx, ty)
        : null;
  }

  @override
  void onPointerMoveStop(PointerMoveEvent event) => _hovered = null;

  void _beginInteraction(MapInteractable it) {
    final data = _data;
    final player = _player;
    if (data == null || player == null) return;
    _pending = it;
    // 已相鄰（含同格）→ 直接由 update 觸發，不再移動。
    if (_chebyshev(player.tileX, player.tileY, it.x, it.y) <= 1) return;
    final (ax, ay) = _approachTileFor(it);
    player.moveTo(ax, ay);
  }

  /// 選一個離玩家最近、可站立的相鄰格作為走近目標；都不可站則退回物件本格。
  (int, int) _approachTileFor(MapInteractable it) {
    final data = _data!;
    final player = _player!;
    int? bestX, bestY;
    var best = 1 << 30;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = it.x + dx, ny = it.y + dy;
        if (nx < 0 || nx >= data.width || ny < 0 || ny >= data.height) continue;
        if (data.isBlocked(nx, ny)) continue;
        final d = _chebyshev(player.tileX, player.tileY, nx, ny);
        if (d < best) {
          best = d;
          bestX = nx;
          bestY = ny;
        }
      }
    }
    if (bestX != null) return (bestX, bestY!);
    return (it.x, it.y);
  }

  static int _chebyshev(int ax, int ay, int bx, int by) {
    final dx = (ax - bx).abs();
    final dy = (ay - by).abs();
    return dx > dy ? dx : dy;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animClock += dt;
    final player = _player;
    final it = _pending;
    // 玩家走到定位（停止且無待走目標）→ 若已相鄰則觸發，否則放棄。
    if (player != null && it != null && player.isIdle) {
      _pending = null;
      if (_chebyshev(player.tileX, player.tileY, it.x, it.y) <= 1) {
        onInteract?.call(it);
      }
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
      if (layer.type == 'collision') continue; // 碰撞為邏輯層，不繪製
      _renderLayer(canvas, layer, data, halfW, halfH);
    }

    _renderTappedCell(canvas, data, halfW, halfH);
    _renderInteractions(canvas, data, halfW, halfH);
  }

  /// 點擊格高亮：半透明紅色填滿菱形 + 紅描邊（tap 移動目標）。
  void _renderTappedCell(
      Canvas canvas, IsoMapData data, double halfW, double halfH) {
    final cell = _tappedCell;
    if (cell == null) return;
    final (tx, ty) = cell;
    if (tx < 0 || tx >= data.width || ty < 0 || ty >= data.height) return;
    final sp = IsoCoord.tileToScreen(tx, ty, halfW, halfH);
    final path = _diamondPath(sp.x, sp.y, halfW, halfH);
    canvas.drawPath(path, Paint()..color = const Color(0x99E53935));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xE0FF5252)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  /// 菱形頂面路徑（頂點在 (topX, topY)）。
  Path _diamondPath(double topX, double topY, double halfW, double halfH) =>
      Path()
        ..moveTo(topX, topY)
        ..lineTo(topX + halfW, topY + halfH)
        ..lineTo(topX, topY + halfH * 2)
        ..lineTo(topX - halfW, topY + halfH)
        ..close();

  /// 互動物件：常駐呼吸標記 + hover/走近時的類型動畫指標。
  void _renderInteractions(
      Canvas canvas, IsoMapData data, double halfW, double halfH) {
    if (data.interactables.isEmpty && _pending == null) return;

    final markerPhase = (_animClock * 0.6) % 1.0;
    for (final it in data.interactables) {
      final sp = IsoCoord.tileToScreen(it.x, it.y, halfW, halfH);
      InteractionIndicator.paintMarker(
        canvas,
        Offset(sp.x, sp.y + halfH),
        it.kind,
        markerPhase,
        halfH * 0.9,
      );
    }

    // pending（走近中）優先，其次 hover。
    final active = _pending ?? _hovered;
    if (active != null) {
      final sp = IsoCoord.tileToScreen(active.x, active.y, halfW, halfH);
      final scale = (halfH / 16).clamp(0.8, 2.0);
      InteractionIndicator.paint(
        canvas,
        Offset(sp.x, sp.y - halfH * 0.4),
        active.kind,
        (_animClock * 1.2) % 1.0,
        scale: scale,
      );
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
    final src = ts.srcRectForId(tileId);
    final dst = Rect.fromLTWH(topX - halfW, topY, halfW * 2, halfH * 2);
    canvas.drawImageRect(img, src, dst, Paint());
  }

  /// 通用灰格：半透明灰黑色扁平菱形 + 白色細線描邊（統一底版風格）。
  void _drawFallbackTile(Canvas canvas, double topX, double topY,
      double halfW, double halfH, int tileId) {
    final path = _diamondPath(topX, topY, halfW, halfH);
    canvas.drawPath(path, Paint()..color = const Color(0x99303038));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xB0FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}
