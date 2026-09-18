import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide PointerMoveEvent;
import 'package:flutter/services.dart';

import '../../config/app_log.dart';
import '../../network/packets/server/s_map_tiles.dart';
import '../../network/packets/server/s_property_pack.dart';
import '../../network/packets/server/s_pc_pack.dart';
import '../../network/packets/server/s_monster_pack.dart';
import '../../network/packets/server/s_npc_pack.dart';
import 'iso_map_data.dart';
import 'map_background_config.dart';
import 'stone_floor.dart';
import 'interaction_indicator.dart';
import 'iso_object_catalog.dart';
import 'iso_object_component.dart';
import 'tile_overlay_layer.dart';
import 'iso_object_graphic.dart';
import 'scene_asset_loader.dart';
import 'iso_monster_component.dart';
import 'iso_player_component.dart';
import 'iso_remote_player_component.dart';

/// 等距地圖渲染元件。
///
/// position 的含義：tile (0,0) 頂點在父元件中的位置（anchor = topLeft）。
/// 採用 topLeft 使 local 座標系與渲染／`event.localPosition`／`screenToTile`
/// 完全一致（`localRender = 螢幕點 - position`），點擊座標不受 anchor 偏移影響。
/// 點擊地圖 tile 時，角色會走向被點擊的格子。
class IsoMapComponent extends PositionComponent
    with TapCallbacks, SecondaryTapCallbacks, PointerMoveCallbacks {
  IsoMapComponent({
    required this.mapId,
    required this.spawnTileX,
    required this.spawnTileY,
    this.spawnFacing = 2,
    this.appearanceKey = 'male',
    this.charName = '',
    this.onPlayerStep,
    this.onPlayerFace,
    this.onInteract,
    this.onTileTap,
    this.onTileSecondaryTap,
    this.monsterAt,
    this.onAttack,
  }) : super(anchor: Anchor.topLeft);

  final int mapId;
  final int spawnTileX;
  final int spawnTileY;

  /// 出生面向（0-7）；由伺服器 S_MAP_CHANGE 的 facing 傳入，換圖後保留朝向。
  final int spawnFacing;

  /// 人物外觀鍵（對應 character_sprites.json 的 sheet key）。
  final String appearanceKey;

  /// 本機角色名稱，顯示於角色頭上。
  final String charName;

  /// 每走一格回呼：(x, y, facing)，由 WorldSceneComponent 注入以送出 C_MOVE。
  final void Function(int x, int y, int facing)? onPlayerStep;

  /// 僅轉向回呼：(facing)，由 WorldSceneComponent 注入以送出 C_FACE。
  final void Function(int facing)? onPlayerFace;

  /// 走到互動物件相鄰一格時觸發（採集／對話／攻擊）。
  final void Function(MapInteractable interactable)? onInteract;

  /// 格子點擊攔截：回傳 true 表示已處理，角色<b>不會</b>走過去。
  /// 洞府布置模式用它把點擊轉成「放置／移除家具」。
  final bool Function(int tx, int ty)? onTileTap;

  /// 右鍵／長按某格。第二個參數是畫面座標，供彈出選單定位。
  final void Function(int tx, int ty, Vector2 screenPos)? onTileSecondaryTap;

  /// 查該格上有沒有可攻擊的怪物，回傳 objId；沒有回 0。
  final int Function(int tx, int ty)? monsterAt;

  /// 走到相鄰格後對該 objId 發動攻擊。
  final void Function(int objId)? onAttack;

  IsoMapData? _data;
  final Map<String, ui.Image> _images = {};
  ui.Image? _bgImage;

  /// 由伺服器 gfxid 載入的底圖左上角（local 座標）；null = 沿用 data.originX/Y。
  /// 底圖的逐圖對齊校正（`map_backgrounds.json`）。
  MapBackgroundOffset _bgTweak = MapBackgroundOffset.none;

  /// 底圖左上角在 local 座標的位置。
  ///
  /// 每次取用時重算，不在載入時存成欄位。格網會在 `S_MAP_TILES` 到達時被
  /// [_rebuildGrid] 整份換掉（邊界或格尺寸變了），而存起來的原點不會跟著更新 ——
  /// 症狀是牆與地板整個分離，偏移量剛好是新舊可走區中心的差，而且不會有任何
  /// 錯誤訊息。算一次是兩個乘法，沒有必要為此冒這個險。
  (double, double)? get _backgroundOrigin {
    final data = _data;
    final bg = _bgImage;
    if (data == null || bg == null) return null;
    final origin = backgroundOrigin(data, bg.width, bg.height);
    return (origin.$1 + _bgTweak.offsetX, origin.$2 + _bgTweak.offsetY);
  }
  IsoPlayerComponent? _player;
  int _localHp = 0;
  int _localHpMax = 0;
  int _localMp = 0;
  int _localMpMax = 0;

  /// 其他玩家，以角色名為鍵。
  ///
  /// 用名字而不是 objId 當鍵，是因為最頻繁的那條路徑（S_CHAR_MOVE、
  /// S_CHAR_FACE）就是以名字識別人物 —— 讓熱路徑不必再查一次表。
  final Map<String, IsoRemotePlayerComponent> _remotePlayers = {};

  /// 地圖還沒載完就收到的玩家名單。
  ///
  /// S_PC_PACK 在進圖後立刻就送到，通常早於 Flame 把地圖載好。直接丟掉的話
  /// 「進圖時已經站在那裡的人」永遠不會出現，要等他們自己動一下才看得到。
  List<RemotePlayerData>? _pendingRemotePlayers;
  String _selfName = '';

  /// 玩家名單的世代編號。
  ///
  /// 建立遠端玩家要 await（載 sprite），這期間可能又來了一份新名單或換了圖。
  /// 回來之後如果世代已經前進，這次的結果就是過期的，直接丟掉。
  int _remoteGeneration = 0;

  /// 動畫時鐘（驅動互動指標的循環相位）。
  double _animClock = 0;

  /// 滑鼠/手指目前指著的互動物件（hover 顯示動畫指標）。
  MapInteractable? _hovered;

  /// 點擊後正在走近、待觸發的互動物件。
  MapInteractable? _pending;

  /// 點擊後正在走近、待攻擊的怪物。
  ///
  /// 與 [_pending] 是同一套模式，但目標是伺服器物件（只有 objId 與格座標），
  /// 不是地圖檔裡的 MapInteractable，所以不能共用同一個欄位。
  int _pendingAttackObjId = 0;
  (int, int)? _pendingAttackCell;

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

  void playLocalPlayerAttack() => _player?.playAttack();
  void playLocalPlayerHurt() => _player?.playHurt();
  void playLocalPlayerDeath() => _player?.playDeath();

  /// 地圖座標是否落在陣列涵蓋範圍內。
  static bool _inMap(IsoMapData data, int tx, int ty) =>
      tx >= data.minMapCoord &&
      tx <= data.maxMapCoordX &&
      ty >= data.minMapCoord &&
      ty <= data.maxMapCoordY;

  /// 底圖左上角座標，使圖片中心對齊「可走區」菱形的中心。
  ///
  /// 可走區 n..m 的螢幕範圍（tileToScreen 回傳菱形頂點）：
  ///   x ∈ [-halfW*size, +halfW*size]  → 中心 0
  ///   y ∈ [2n*halfH, 2m*halfH + 2*halfH] → 中心 halfH*(n + m + 1)
  ///
  /// 注意 y 的中心是 (n + m + 1) 不是 (n + m + 2)：底邊那格自身還要
  /// 往下延伸一個 tileHeight，取平均後只多半格。差一格會讓美術偏 16px。
  static (double, double) backgroundOrigin(IsoMapData data, int bgW, int bgH) {
    final halfH = data.halfTileHeight;
    // 投影在陣列索引空間進行，故座標要先減掉 coordOffset
    final n = data.toIndex(data.walkMinCoord);
    final m = data.toIndex(data.walkMaxCoord);
    const centerX = 0.0;
    final centerY = halfH * (n + m + 1);
    return (centerX - bgW / 2, centerY - bgH / 2);
  }

  /// 已放上畫面的伺服器場景物件（key = objId），供增量更新與移除。
  final Map<int, IsoObjectComponent> _propertyComponents = {};

  /// 對應的原始資料，重建碰撞時需要 footprint 與 blocking。
  final Map<int, PropertyObject> _propertyData = {};

  /// 格子高亮層（放置預覽／搬動／GM 碰撞編輯共用）。
  TileOverlayLayer? _overlay;

  /// 預覽用的半透明家具「幽靈」。
  IsoObjectComponent? _ghost;

  /// 伺服器指定的地形不可通行格（地圖座標）。
  ///
  /// 存起來是因為 [_rebuildPropertyCollision] 每次都會從 [_baseCollision] 重來，
  /// 地形必須在那之前先蓋回去。
  List<(int, int)> _terrainBlocked = const [];

  /// 蓋任何物件之前的碰撞層快照。
  ///
  /// 移除家具時必須把格子還原成「原本可不可走」，而不是一律設為可走 ——
  /// generic 地圖的外圈邊界本來就不可走，整片清空會讓角色走出地圖。
  List<List<int>>? _baseCollision;

  /// 套用伺服器推送的場景物件清單（S_PROPERTY_PACK）。
  ///
  /// 逐筆 upsert：既有 objId 先移除舊元件再重建（座標或外觀可能改變），
  /// 不在清單中的既有物件<b>保留</b> —— 移除一律由 S_OBJECT_REMOVE 負責，
  /// 因為這個封包同時服務「進圖整批」與「單一物件出現」兩種情境。
  Future<void> applyServerProperties(List<PropertyObject> properties) async {
    if (properties.isEmpty) return;
    final data = _data;
    if (data == null) return;

    final catalog = await IsoObjectCatalog.load();
    for (final p in properties) {
      final def = catalog[p.pngid];
      if (def == null) {
        AppLog.d('ISO-PROP', '找不到物件定義 pngid=${p.pngid}（objId=${p.objId}）');
        continue;
      }
      _propertyComponents.remove(p.objId)?.removeFromParent();

      final graphic = await ObjectGraphic.loadForDir(def.dir, def.image);
      final comp = IsoObjectComponent(
        def: def,
        // 伺服器送的是地圖座標，元件吃的是陣列索引 —— 這裡是兩個座標空間的交界
        tileX: data.toIndex(p.x),
        tileY: data.toIndex(p.y),
        zBias: 0,
        mapData: data,
        graphic: graphic,
        tilesW: def.tilesW,
      );
      _propertyComponents[p.objId] = comp;
      _propertyData[p.objId] = p;
      add(comp);
    }
    _rebuildPropertyCollision(data);
    AppLog.d('ISO-PROP',
        '場景物件已更新：本次 ${properties.length} 筆，畫面上共 ${_propertyComponents.length} 個');
  }

  /// 依當前所有伺服器物件重建碰撞蓋章。
  ///
  /// 刻意整批重建而非增量增刪 —— 多個物件的 footprint 可能重疊，
  /// 逐格清除很容易把還有別的物件佔著的格子誤放行。
  void _rebuildPropertyCollision(IsoMapData data) {
    final grid = _ensureCollisionGrid(data);
    _baseCollision ??= [for (final row in grid) List<int>.from(row)];

    final base = _baseCollision!;
    for (var y = 0; y < grid.length; y++) {
      for (var x = 0; x < grid[y].length; x++) {
        grid[y][x] = base[y][x];
      }
    }

    // 地形先蓋回去：它屬於「物件以外的底層碰撞」，順序在物件之前。
    // 漏了這步的話，拆掉一張桌子會把它旁邊的牆一併變成可走。
    for (final (mx, my) in _terrainBlocked) {
      final tx = data.toIndex(mx);
      final ty = data.toIndex(my);
      if (ty >= 0 && ty < grid.length && tx >= 0 && tx < grid[ty].length) {
        grid[ty][tx] = 1;
      }
    }

    for (final p in _propertyData.values) {
      if (!p.blocking) continue;
      // 伺服器送地圖座標，碰撞層吃陣列索引
      final ax = data.toIndex(p.x);
      final ay = data.toIndex(p.y);
      // 佔格由錨點往 x、y 遞減延伸，與伺服器 MapGrid 一致
      for (var j = 0; j < p.footprintH; j++) {
        for (var i = 0; i < p.footprintW; i++) {
          final tx = ax - i;
          final ty = ay - j;
          if (ty >= 0 && ty < grid.length && tx >= 0 && tx < grid[ty].length) {
            grid[ty][tx] = 1;
          }
        }
      }
    }
  }

  /// 移除單一場景物件（S_OBJECT_REMOVE）。
  void removeServerObject(int objId) {
    _propertyComponents.remove(objId)?.removeFromParent();
    if (_propertyData.remove(objId) != null) {
      final data = _data;
      if (data != null) _rebuildPropertyCollision(data);
    }
  }

  /// 伺服器指定的地面：`(陣列索引x, 陣列索引y)` → 圖磚影像。
  ///
  /// 改用一張張獨立的圖磚，而不是圖集切格。圖集對機器有效率，對人很不友善 ——
  /// 想知道某編號長什麼樣得先算索引再去圖上數格子。獨立檔案看檔名就知道，
  /// 要換掉某一塊也只是覆蓋一個檔。這個量級（十幾張）載入成本可以忽略。
  final Map<(int, int), ui.Image> _serverTiles = {};

  /// 套用伺服器送來的圖磚（S_MAP_TILES）。
  ///
  /// 碰撞由 `generic()` 與伺服器的 `map_collision` 決定。
  Future<void> applyMapTiles(SMapTiles tiles) async {
    if (!tiles.isValid) return;
    var data = _data;
    if (data == null) return;

    final tileWidth = tiles.tileWidth;
    final tileHeight = tiles.tileHeight;

    // 伺服器的地圖邊界與目前的格網不同 → 整份重建。
    //
    // 少了這一段，前端就永遠是 onLoad 時那份 31..50 的 20×20 底版：
    // 資料庫把地圖改大之後，超出 50 的圖磚會寫到陣列外、碰撞陣列不會跟著長，
    // 而玩家的 clamp 會把人**鎖在舊邊界內走不出去** —— 而且完全沒有錯誤訊息，
    // 只是走到某一格就停住。地圖大小的唯一來源是伺服器的 map 表。
    if (tiles.walkMin != data.walkMinCoord ||
        tiles.walkMax != data.walkMaxCoord ||
        tileWidth != data.tileWidth ||
        tileHeight != data.tileHeight) {
      AppLog.d('MAP',
          '地圖規格改變：${data.walkMinCoord}..${data.walkMaxCoord}'
          ' @${data.tileWidth}x${data.tileHeight}'
          ' → ${tiles.walkMin}..${tiles.walkMax}'
          ' @${tileWidth}x$tileHeight，重建格網');
      await _rebuildGrid(tiles.walkMin, tiles.walkMax,
          tileWidth, tileHeight);
      data = _data;
      if (data == null) return;
    }

    // 先把用得到的圖磚檔載進來（同一編號只載一次）
    final images = <int, ui.Image>{};
    for (final id in tiles.ground.map((c) => c.$3).toSet()) {
      final path = tiles.pathFor(id);
      if (path == null) {
        AppLog.d('MAP', '圖磚編號 $id 不在對照表裡，該格不鋪');
        continue;
      }
      final img = await SceneAssetLoader.loadTileAtlas(path);
      if (img != null) {
        images[id] = img;
      } else {
        AppLog.d('MAP', '圖磚載不到：$path');
      }
    }

    _serverTiles.clear();
    for (final (x, y, id) in tiles.ground) {
      final img = images[id];
      if (img == null) continue;
      // 伺服器送的是遊戲座標，繪製吃陣列索引 —— 換算只在這一處
      _serverTiles[(data.toIndex(x), data.toIndex(y))] = img;
    }

    // 地面換了，錄好的地磚 Picture 就過期了
    _invalidateGround();
    AppLog.d('MAP',
        '已套用伺服器圖磚：地圖${tiles.mapId} ${_serverTiles.length} 格 / '
        '${images.length} 種');
  }

  /// 套用伺服器指定的地形碰撞（S_MAP_INFO 的 blocked／S_MAP_COLLISION）。
  ///
  /// 寫進 [_terrainBlocked] 而非直接改碰撞層 —— 碰撞層每次重建都會從
  /// [_baseCollision] 重來，直接改會在下一次放置家具時被抹掉。
  void applyTerrainCollision(List<(int, int)> blocked) {
    _terrainBlocked = List.of(blocked);
    final data = _data;
    if (data != null) _rebuildPropertyCollision(data);
  }

  /// 目前的地形碰撞格（地圖座標），供 GM 編輯模式判斷該格是開是關。
  List<(int, int)> get terrainBlocked => _terrainBlocked;

  /// 該格是否不可通行（含地形與家具）；地圖尚未載入時視為擋住。
  bool isTileBlocked(int x, int y) => _data?.isBlocked(x, y) ?? true;

  /// 該格是否在地圖的合法可走範圍內。
  bool isInMap(int x, int y) {
    final data = _data;
    if (data == null) return false;
    return x >= data.walkMinCoord &&
        x <= data.walkMaxCoord &&
        y >= data.walkMinCoord &&
        y <= data.walkMaxCoord;
  }

  /// 高亮一組格子（地圖座標）。傳空集合等同清除。
  void highlightTiles(Iterable<(int, int)> cells, Color color) {
    final data = _data;
    if (data == null) return;
    _overlay?.showAll(
      cells.map((c) => (data.toIndex(c.$1), data.toIndex(c.$2))),
      color,
    );
  }

  void clearHighlight() => _overlay?.clear();

  /// 顯示半透明的家具預覽（幽靈）。
  ///
  /// 同一個 pngid 連續移動時會沿用既有元件只改位置，避免每點一格就重載一次圖。
  Future<void> showGhost(int pngid, int mapX, int mapY) async {
    final data = _data;
    if (data == null) return;
    final catalog = await IsoObjectCatalog.load();
    final def = catalog[pngid];
    if (def == null) {
      AppLog.d('ISO-PROP', '預覽找不到物件定義 pngid=$pngid');
      return;
    }
    clearGhost();
    final graphic = await ObjectGraphic.loadForDir(def.dir, def.image);
    final ghost = IsoObjectComponent(
      def: def,
      tileX: data.toIndex(mapX),
      tileY: data.toIndex(mapY),
      zBias: 0,
      mapData: data,
      graphic: graphic,
      tilesW: def.tilesW,
      opacity: 0.5,
    );
    _ghost = ghost;
    add(ghost);
  }

  void clearGhost() {
    _ghost?.removeFromParent();
    _ghost = null;
  }

  /// 把某個已放置家具的元件設為半透明（搬動中），或還原。
  void setObjectOpacity(int objId, double opacity) {
    _propertyComponents[objId]?.opacity = opacity;
  }

  /// 清空所有伺服器場景物件（換圖時呼叫）。
  void clearServerProperties() {
    for (final c in _propertyComponents.values) {
      c.removeFromParent();
    }
    _propertyComponents.clear();
    _propertyData.clear();
    final data = _data;
    if (data != null && _baseCollision != null) _rebuildPropertyCollision(data);
  }

  /// 套用伺服器指定的場景底圖（S_MAP_INFO 的 gfxid），並對齊格網中心。
  ///
  /// gfxid 走與 property.pngid 相同的編號空間 —— object_catalog.json 的物件 id。
  /// 底圖僅置中繪製，不參與碰撞，也不改變格網尺寸；等距菱形疊在圖上，
  /// 露出的留白剛好可以用來評估格數要縮到多少。
  Future<void> applyBackground(int gfxid) async {
    final data = _data;
    if (data == null) return;

    ui.Image? bg;
    String source;

    // 優先：map 表的 gfxid → object_catalog.json（與 property.pngid 同一套編號）
    if (gfxid > 0) {
      final catalog = await IsoObjectCatalog.load();
      final def = catalog[gfxid];
      if (def != null) {
        bg = switch (def.dir) {
          'tiles' => await SceneAssetLoader.loadTileAtlas(def.image),
          'objects' => await SceneAssetLoader.loadObjectAtlas(def.image),
          _ => await SceneAssetLoader.loadSceneImage(def.image),
        };
        source = '${def.dir}/${def.image} (gfxid=$gfxid)';
      } else {
        AppLog.d('ISO-BG', '找不到底圖定義 gfxid=$gfxid，改用 assets/maps/$mapId.png');
        source = '';
      }
    } else {
      source = '';
    }

    // 退回：assets/maps/{mapId}.png 的一圖一地圖慣例
    if (bg == null) {
      bg = await SceneAssetLoader.loadMapBackground(mapId);
      source = 'assets/maps/$mapId.png';
    }
    if (bg == null) return;

    _bgImage = bg;

    // 對齊「可走區」菱形的中心 —— 不是整張陣列的中心。
    // generic 地圖在陣列外圍留了一圈不可走的邊界（索引 0），
    // 若照整張陣列置中，底圖會往上偏半格（halfH）。
    // tileToScreen 回傳菱形頂點，故可走區 n..m 的螢幕範圍為：
    //   x ∈ [-halfW*size, +halfW*size]，y ∈ [2n*halfH, 2m*halfH + 2*halfH]
    final size = data.walkSize;
    final diamondW = size * data.tileWidth;
    final diamondH = size * data.tileHeight;

    // 美術本身含牆面／高度時，圖中的地面菱形不在畫布中心，需逐圖校正。
    // 只存校正量；原點本身由 [_backgroundOrigin] 依當下的格網即時算。
    _bgTweak = await MapBackgroundConfig.forMap(mapId);
    final origin = _backgroundOrigin!;

    AppLog.d(
        'ISO-BG',
        '底圖 $source ${bg.width}x${bg.height} 已對齊可走區中心'
        ' | 可走 ${data.walkMinCoord}..${data.walkMaxCoord}'
        '（$size 格，tile ${data.tileWidth}x${data.tileHeight}）'
        ' → 菱形 ${diamondW}x$diamondH'
        ' | 建議底圖尺寸 ${diamondW}x$diamondW（上下各留白 ${diamondW ~/ 4}）'
        '${_bgTweak.offsetX == 0 && _bgTweak.offsetY == 0 ? '' : ' | 校正位移 (${_bgTweak.offsetX}, ${_bgTweak.offsetY})'}'
        ' | 原點 (${origin.$1.toStringAsFixed(0)}, ${origin.$2.toStringAsFixed(0)})');
  }

  /// 伺服器移動修正：把角色硬拉回指定格（不觸發 onStep）。
  void snapPlayerTo(int tx, int ty, {int? facing}) =>
      _player?.snapTo(tx, ty, facing: facing);

  /// 更新本機角色頭頂的 HP／MP；地圖載入中時先快取，建好角色再套用。
  void setLocalPlayerVitals({
    required int hp,
    required int hpMax,
    required int mp,
    required int mpMax,
  }) {
    _localHp = hp;
    if (hpMax > 0) _localHpMax = hpMax;
    _localMp = mp;
    if (mpMax > 0) _localMpMax = mpMax;
    _player?.applyVitals(
      hp: _localHp,
      hpMax: _localHpMax,
      mp: _localMp,
      mpMax: _localMpMax,
    );
  }

  void setRemotePlayerHp(int objId, int hp, int hpMax) {
    for (final player in _remotePlayers.values) {
      if (player.objId == objId) {
        player.applyCharacterHp(hp, hpMax);
        return;
      }
    }
  }

  void setRemotePlayerMp(int objId, int mp, int mpMax) {
    for (final player in _remotePlayers.values) {
      if (player.objId == objId) {
        player.applyCharacterMp(mp, mpMax);
        return;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    // 程式底版：尺寸對齊伺服器 map 表（bounds 31..50 → 可走 (31,31)..(50,50)
    // 共 20×20 格、中心 (40,40)）。
    //
    // 地面長什麼樣由伺服器的 S_MAP_TILES 決定 —— 封包到達時
    // [applyMapTiles] 會整份換掉 _data。這裡先建一份能立刻渲染的底版，
    // 讓封包還沒到的那幾幀有東西可畫。
    //
    // 前端**不再自己持有地圖資料**：先前 assets/maps/0.json 同時存了地圖邊界，
    // 與伺服器 map 表的 min_x/max_x 重複，改一邊另一邊不會跟著動。
    _data = IsoMapData.generic(
      mapId: mapId,
      // 洞府的格子比其他地圖大：家具是原生尺寸、角色放大 2.5 倍，格子太小會讓
      // 一步只移動半個身寬，走起來像在原地碎步。112x56 讓一步約等於一個身寬，
      // 同時 10 格 x 112 = 1120px 正好是牆面美術的地板寬度。
      tileWidth: mapId == 0 ? 112 : 64,
      tileHeight: mapId == 0 ? 56 : 32,
    );
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

    // 上面的 await 期間 S_MAP_TILES 可能已經到了（見下方玩家建立前的說明）
    if (!identical(_data, data)) {
      await _applyPendingLists();
      return;
    }

    // 格子高亮層：放置預覽／搬動／GM 碰撞編輯共用，壓在所有物件之下。
    _overlay = TileOverlayLayer(mapData: data);
    add(_overlay!);

    // 布置物件（prop）：依 catalog 建元件並加入為子元件（與玩家一起深度排序），
    // blocking 物件的 footprint 格 stamp 進碰撞層 → mapData.isBlocked 生效。
    await _loadObjects(data);

    // 載入人物 sprite（缺圖回 null → 玩家用 canvas fallback）。
    final spriteSet =
        await SceneAssetLoader.loadCharacterSprites(appearanceKey);

    // 上面幾個 await 期間，S_MAP_TILES 可能已經到了：_rebuildGrid 會換掉 _data
    // 並建好玩家。這時再建一個就會有兩個自己 —— 先建的留在出生點變成殘影，
    // 手上操作的卻是綁著舊格網的這個（沒有家具碰撞、邊界也是舊的）。
    if (!identical(_data, data) || _player != null) {
      await _applyPendingLists();
      return;
    }

    _player = IsoPlayerComponent(
      initialTileX: spawnTileX.clamp(data.minMapCoord, data.maxMapCoordX),
      initialTileY: spawnTileY.clamp(data.minMapCoord, data.maxMapCoordY),
      initialFacing: spawnFacing,
      mapData: data,
      // 換圖改由伺服器權威 portal 協定驅動：每走一格回報 (x,y,facing)，
      // 由 WorldSceneComponent 送 C_MOVE 並偵測是否踏入傳送點。
      onStep: (x, y, facing) => onPlayerStep?.call(x, y, facing),
      onFace: onPlayerFace,
      spriteSet: spriteSet,
      displayName: charName,
      vitalHp: _localHp,
      vitalHpMax: _localHpMax,
      vitalMp: _localMp,
      vitalMpMax: _localMpMax,
    );
    add(_player!);
    await _applyPendingLists();
  }

  /// 地圖載好之前收到的名單，現在才補上。
  Future<void> _applyPendingLists() async {
    final pending = _pendingRemotePlayers;
    if (pending != null) {
      _pendingRemotePlayers = null;
      await applyRemotePlayers(pending, selfName: _selfName);
    }
    final pendingMonsters = _pendingMonsters;
    if (pendingMonsters != null) {
      _pendingMonsters = null;
      applyMonsters(pendingMonsters);
    }
    final pendingNpcs = _pendingNpcs;
    if (pendingNpcs != null) {
      _pendingNpcs = null;
      applyNpcs(pendingNpcs);
    }
  }

  // ── 其他玩家 ────────────────────────────────────────────────────────

  /// 套用整份玩家名單（S_PC_PACK）。
  ///
  /// 名單是<b>完整</b>的：不在名單裡的人一律移除。伺服器每次有人進出就整包
  /// 重送，所以這裡不需要（也不該）保留舊的人 —— 那正是鬼影的來源。
  /// 名單含收件者自己，在這裡濾掉。
  Future<void> applyRemotePlayers(
    List<RemotePlayerData> players, {
    required String selfName,
  }) async {
    _selfName = selfName;
    final data = _data;
    if (data == null) {
      _pendingRemotePlayers = players;
      return;
    }
    final generation = ++_remoteGeneration;

    final incoming = {
      for (final p in players)
        if (p.name != selfName) p.name: p,
    };

    for (final name in _remotePlayers.keys.toList()) {
      if (!incoming.containsKey(name)) {
        _remotePlayers.remove(name)?.removeFromParent();
      }
    }

    for (final p in incoming.values) {
      final existing = _remotePlayers[p.name];
      if (existing != null) {
        existing.applyServerPosition(p.x, p.y, facing: p.heading);
        continue;
      }
      final comp = await createRemotePlayer(
        charName: p.name,
        objId: p.objId,
        x: p.x,
        y: p.y,
        facing: p.heading,
        sex: p.sex,
        mapData: data,
      );
      // await 期間可能又來了一份名單或換了圖 —— 這次的結果已經過期
      if (generation != _remoteGeneration || _data != data) {
        return;
      }
      _remotePlayers[p.name] = comp;
      add(comp);
    }
  }

  /// 其他玩家走了一步（S_CHAR_MOVE）。
  void moveRemotePlayer(String name, int x, int y, int facing) {
    _remotePlayers[name]?.applyServerPosition(x, y, facing: facing);
  }

  /// 其他玩家轉向（S_CHAR_FACE）。
  void faceRemotePlayer(String name, int facing) {
    final p = _remotePlayers[name];
    if (p != null) {
      p.snapTo(p.tileX, p.tileY, facing: facing);
    }
  }

  // ── 怪物 ──────────────────────────────────────────────────────────

  /// 場上的怪物，以 objId 為鍵。
  ///
  /// S_MONSTER_PACK 是 upsert（同時服務「進圖整批」與「一隻新怪出現」），
  /// 移除一律由 S_OBJECT_REMOVE 負責 —— 與伺服器端的約定一致。
  final Map<int, IsoMonsterComponent> _monsters = {};

  /// 地圖還沒載完就收到的怪物名單。
  List<MonsterObject>? _pendingMonsters;

  /// 依伺服器給的可走區邊界重建格網。
  ///
  /// 會連帶重建所有吃 mapData 的子元件（高亮層、家具、玩家）——
  /// 它們持有的是舊那份 [IsoMapData] 的參考，留著就會用舊的邊界算座標。
  /// 玩家的格座標刻意保留，重建後回到同一格。
  Future<void> _rebuildGrid(
      int walkMin, int walkMax, int tileWidth, int tileHeight) async {
    final prev = _player;
    final keepX = prev?.tileX;
    final keepY = prev?.tileY;
    final keepFacing = prev?.facing ?? spawnFacing;

    _data = IsoMapData.generic(
      minCoord: walkMin,
      maxCoord: walkMax,
      mapId: mapId,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    final data = _data!;
    _baseCollision = null;
    _serverTiles.clear();
    _invalidateGround();

    scale = Vector2.all(data.renderScale);
    size = Vector2(
      (data.width + data.height - 2) * data.halfTileWidth + data.tileWidth,
      (data.width + data.height - 2) * data.halfTileHeight + data.tileHeight,
    );

    _overlay?.removeFromParent();
    _overlay = TileOverlayLayer(mapData: data);
    add(_overlay!);

    for (final c in _propertyComponents.values) {
      c.removeFromParent();
    }
    _propertyComponents.clear();
    final props = List.of(_propertyData.values);
    _propertyData.clear();

    for (final m in _monsters.values) {
      m.removeFromParent();
    }
    _monsters.clear();
    for (final c in _corpses) {
      c.removeFromParent();
    }
    _corpses.clear();

    for (final n in _npcs.values) {
      n.removeFromParent();
    }
    _npcs.clear();

    for (final p in _remotePlayers.values) {
      p.removeFromParent();
    }
    _remotePlayers.clear();

    await _loadObjects(data);

    prev?.removeFromParent();
    final spriteSet = await SceneAssetLoader.loadCharacterSprites(appearanceKey);
    _player = IsoPlayerComponent(
      initialTileX: (keepX ?? spawnTileX).clamp(walkMin, walkMax),
      initialTileY: (keepY ?? spawnTileY).clamp(walkMin, walkMax),
      initialFacing: keepFacing,
      mapData: data,
      onStep: (x, y, facing) => onPlayerStep?.call(x, y, facing),
      onFace: onPlayerFace,
      spriteSet: spriteSet,
      displayName: charName,
      vitalHp: _localHp,
      vitalHpMax: _localHpMax,
      vitalMp: _localMp,
      vitalMpMax: _localMpMax,
    );
    add(_player!);

    // 家具是伺服器推送的，重建後要重放一次，否則整圖的擺設會消失
    if (props.isNotEmpty) {
      await applyServerProperties(props);
    }
  }

  /// 套用怪物名單（S_MONSTER_PACK）。逐筆 upsert，不移除不在清單裡的。
  void applyMonsters(List<MonsterObject> monsters) {
    final data = _data;
    if (data == null) {
      _pendingMonsters = monsters;
      return;
    }
    for (final m in monsters) {
      // 已經死掉的不要生出來 —— 整包重送時死屍還在名單裡的話會詐屍
      if (m.currentHp <= 0) {
        removeMonster(m.objId);
        continue;
      }
      // 座標<b>不</b>換算成陣列索引。IsoPlayerComponent 這一族（玩家、遠端
      // 玩家、怪物）吃的就是地圖座標，內部自己 toIndex；而 IsoObjectComponent
      // （家具）吃的才是索引。兩族的慣例不同，換錯邊會整批偏移 coordOffset 格
      // ——不會拋例外，只是怪物全部跑到牆外面。
      final existing = _monsters[m.objId];
      if (existing != null) {
        existing.applyServerPosition(m.x, m.y, facing: m.heading);
        existing.applyHp(m.currentHp, m.maxHp);
        continue;
      }
      final comp = createMonster(
        objId: m.objId,
        name: m.name,
        x: m.x,
        y: m.y,
        facing: m.heading,
        maxHp: m.maxHp,
        currentHp: m.currentHp,
        mapData: data,
      );
      _monsters[m.objId] = comp;
      add(comp);
    }
  }

  /// 怪物走了一步（S_NPC_MOVE）。
  void moveMonster(int objId, int x, int y, int heading) {
    _monsters[objId]?.applyServerPosition(x, y, facing: heading);
  }

  /// 怪物血量變化（S_HP_UPDATE）。
  void setMonsterHp(int objId, int hp, int maxHp) {
    _monsters[objId]?.applyHp(hp, maxHp);
  }

  /// 怪物死亡或離場（S_OBJECT_REMOVE）。
  ///
  /// 血量已經歸零的是死亡：留下屍體（半透明停留幾秒）再移除；
  /// 其餘（波次清場、GM 移除）直接消失。
  void removeMonster(int objId) {
    final m = _monsters.remove(objId);
    if (m == null) return;
    if (m.currentHp > 0) {
      m.removeFromParent();
      return;
    }
    _corpses.add(m);
    m.beginCorpse(() {
      _corpses.remove(m);
      m.removeFromParent();
    });
  }

  /// 還在播屍體的怪。已不在 [_monsters] 裡，不再接受移動與血量更新。
  final Set<IsoMonsterComponent> _corpses = {};

  /// 怪物的攻擊演出：先面向目標再揮。目標只可能是玩家（其他玩家或自己）。
  void playMonsterAttack(int objId, int targetObjId) {
    final m = _monsters[objId];
    if (m == null) return;
    final cell = _playerCellByObjId(targetObjId);
    if (cell != null) m.faceToward(cell.$1, cell.$2);
    m.playAttack();
  }

  /// 怪物被打中的演出。
  void playMonsterHurt(int objId) => _monsters[objId]?.playHurt();

  (int, int)? _playerCellByObjId(int objId) {
    for (final p in _remotePlayers.values) {
      if (p.objId == objId) return (p.tileX, p.tileY);
    }
    return playerCell; // 不是其他玩家就是自己
  }

  /// 清空所有怪物（換圖時），連同還在播的屍體。
  void clearMonsters() {
    for (final m in _monsters.values) {
      m.removeFromParent();
    }
    _monsters.clear();
    for (final c in _corpses) {
      c.removeFromParent();
    }
    _corpses.clear();
    _pendingMonsters = null;
  }

  // ── NPC（可對話、商店）────────────────────────────────────────────

  /// 場上的 NPC，以 objId 為鍵。
  ///
  /// 沿用怪物元件來畫（沒有美術時是佔位圖形），但不畫血條。採集物與裝飾
  /// （gather／scenery）不在這裡 —— 它們不會動，也不需要一個角色元件。
  /// 以前 NPC 完全沒有畫出來，伺服器的 NPC 行為（遊走、轉身、說話）在畫面上看不到。
  final Map<int, IsoMonsterComponent> _npcs = {};

  /// 地圖還沒載完就收到的 NPC 名單。
  List<NpcObject>? _pendingNpcs;

  static bool _rendersNpc(NpcObject n) =>
      n.type == NpcObjectType.npc || n.type == NpcObjectType.shop;

  /// 套用 NPC 名單（S_NPC_PACK）。逐筆 upsert，與怪物同樣的約定。
  void applyNpcs(List<NpcObject> npcs) {
    final data = _data;
    if (data == null) {
      _pendingNpcs = [...?_pendingNpcs, ...npcs];
      return;
    }
    for (final n in npcs) {
      if (!_rendersNpc(n)) continue;
      final existing = _npcs[n.objId];
      if (existing != null) {
        existing.applyServerPosition(n.x, n.y, facing: n.heading);
        continue;
      }
      final comp = createMonster(
        objId: n.objId,
        name: n.name,
        x: n.x,
        y: n.y,
        facing: n.heading,
        maxHp: 0,
        currentHp: 1,
        mapData: data,
        showHpBar: false,
      );
      _npcs[n.objId] = comp;
      add(comp);
    }
  }

  /// NPC 走了一步或原地轉身（S_NPC_MOVE；座標不變就只轉向）。
  void moveNpc(int objId, int x, int y, int heading) {
    _npcs[objId]?.applyServerPosition(x, y, facing: heading);
  }

  /// NPC 離場（S_OBJECT_REMOVE）。NPC 不會死，直接移除。
  void removeNpc(int objId) {
    _npcs.remove(objId)?.removeFromParent();
  }

  /// 換圖時清掉場上的 NPC。
  void clearNpcs() {
    for (final n in _npcs.values) {
      n.removeFromParent();
    }
    _npcs.clear();
    _pendingNpcs = null;
  }

  /// 頭上對話泡泡（S_BUBBLE_DIALOG）。NPC 優先，其次怪物。
  void showBubble(int objId, String text) {
    (_npcs[objId] ?? _monsters[objId])?.say(text);
  }

  /// 該格上的其他玩家角色名；沒有回 null。供右鍵選單用。
  ///
  /// 回名字而不是 objId，是因為現有的選單動作（邀請組隊、驅逐、密語）
  /// 在協定上都以角色名指定對象。
  String? remotePlayerNameAt(int tx, int ty) {
    for (final p in _remotePlayers.values) {
      if (p.tileX == tx && p.tileY == ty) return p.charName;
    }
    return null;
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

    final (ix, iy) = data.screenToTile(event.localPosition);
    // screenToTile 算出的是陣列索引，換成地圖座標後才能與伺服器對話
    final tx = data.toMapCoord(ix);
    final ty = data.toMapCoord(iy);

    AppLog.d('ISO-TAP',
        'tile=($tx,$ty) player=(${player.tileX},${player.tileY}) '
        'inRange=${_inMap(data, tx, ty)}');

    if (!_inMap(data, tx, ty)) {
      // 點到地圖外（牆面、留白）：往地圖邊緣最靠近點擊處的格子走，而不是沒反應。
      // Shift 轉向與布置工具只對地圖內的格子有意義，這裡不處理。
      if (!HardwareKeyboard.instance.isShiftPressed) {
        player.moveTo(
          tx.clamp(data.walkMinCoord, data.walkMaxCoord),
          ty.clamp(data.walkMinCoord, data.walkMaxCoord),
        );
      }
      return;
    }

    // 布置模式優先：吃掉點擊，不讓角色跑過去
    if (onTileTap != null && onTileTap!(tx, ty)) return;

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

    // 點到怪物 → 走近至相鄰一格再攻擊。放在互動物件之前判斷：
    // 怪站在採集點上時，玩家的意圖幾乎一定是打它。
    final monsterObjId = monsterAt?.call(tx, ty) ?? 0;
    if (monsterObjId != 0) {
      _beginAttack(monsterObjId, tx, ty);
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

  /// 右鍵（桌機）與長按（觸控）都導向同一個處理 ——
  /// 觸控裝置沒有右鍵，只接 onSecondaryTapDown 的話手機上永遠開不了選單。
  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) =>
      _handleSecondaryTap(event.localPosition, event.canvasPosition);

  @override
  void onLongTapDown(TapDownEvent event) =>
      _handleSecondaryTap(event.localPosition, event.canvasPosition);

  void _handleSecondaryTap(Vector2 localPos, Vector2 canvasPos) {
    final data = _data;
    if (data == null) return;

    final player = _player;
    if (player != null && player.hitTestVisualPoint(localPos)) {
      onTileSecondaryTap?.call(player.tileX, player.tileY, canvasPos);
      return;
    }

    final remotes = _remotePlayers.values.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    for (final remote in remotes) {
      if (remote.hitTestVisualPoint(localPos)) {
        onTileSecondaryTap?.call(remote.tileX, remote.tileY, canvasPos);
        return;
      }
    }

    final (ix, iy) = data.screenToTile(localPos);
    final tx = data.toMapCoord(ix);
    final ty = data.toMapCoord(iy);
    if (!_inMap(data, tx, ty)) return;
    onTileSecondaryTap?.call(tx, ty, canvasPos);
  }

  /// 玩家自己所在的格（供右鍵命中判定）。地圖未載入時回 null。
  ///
  /// `IsoPlayerComponent.tileX/tileY` 已經是<b>地圖座標</b>（它內部才用
  /// `toIndex` 換算成螢幕位置），所以這裡不能再轉一次。
  (int, int)? get playerCell {
    final p = _player;
    if (p == null) return null;
    return (p.tileX, p.tileY);
  }

  // ── 互動框架（hover → 走近 → 觸發）─────────────────────────

  @override
  void onPointerMove(PointerMoveEvent event) {
    final data = _data;
    if (data == null) return;
    final (ix, iy) = data.screenToTile(event.localPosition);
    // screenToTile 算出的是陣列索引，換成地圖座標後才能與伺服器對話
    final tx = data.toMapCoord(ix);
    final ty = data.toMapCoord(iy);
    _hovered = _inMap(data, tx, ty)
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

  /// 開始一次攻擊：已相鄰就立刻打，否則先走過去。
  void _beginAttack(int objId, int tx, int ty) {
    final player = _player;
    if (player == null) return;
    _pending = null;      // 攻擊取消掉原本的互動意圖
    if (_chebyshev(player.tileX, player.tileY, tx, ty) <= 1) {
      onAttack?.call(objId);
      return;
    }
    _pendingAttackObjId = objId;
    _pendingAttackCell = (tx, ty);
    final (ax, ay) = _approachTileNear(tx, ty);
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

  /// 選一個離玩家最近、可站立的相鄰格（**吃地圖座標**）。
  ///
  /// 不能沿用 [_approachTileFor] —— 那支的邊界檢查用的是陣列索引
  /// （`nx >= data.width`），而怪物的座標是地圖座標（31..50）。
  /// 直接餵進去會因為 31 > 22 而每一格都被判定越界，走近永遠失敗。
  (int, int) _approachTileNear(int tx, int ty) {
    final data = _data!;
    final player = _player!;
    int? bestX, bestY;
    var best = 1 << 30;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = tx + dx, ny = ty + dy;
        if (!_inMap(data, nx, ny)) continue;
        if (data.isBlocked(nx, ny)) continue;
        final d = _chebyshev(player.tileX, player.tileY, nx, ny);
        if (d < best) {
          best = d;
          bestX = nx;
          bestY = ny;
        }
      }
    }
    // 四周都站不了就退回原地，讓 update 的相鄰判定自然失敗、放棄這次攻擊
    return bestX != null ? (bestX, bestY!) : (player.tileX, player.tileY);
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

    // 待攻擊的怪物：同樣等走到定位才發動。走不到就放棄，不要一直重試 ——
    // 目標可能已經死了或被牆擋住，無限重試只會塞滿封包。
    final cell = _pendingAttackCell;
    if (player != null && cell != null && player.isIdle) {
      final objId = _pendingAttackObjId;
      _pendingAttackObjId = 0;
      _pendingAttackCell = null;
      if (_chebyshev(player.tileX, player.tileY, cell.$1, cell.$2) <= 1) {
        onAttack?.call(objId);
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
      final origin = _backgroundOrigin;
      canvas.drawImage(
          bg,
          origin == null
              ? Offset(data.originX, data.originY)
              : Offset(origin.$1, origin.$2),
          Paint());
    }

    final halfW = data.halfTileWidth;
    final halfH = data.halfTileHeight;

    // 地磚層錄成 Picture 只畫一次，之後每幀重播。
    //
    // 石板的磨損細節（裂痕分岔、缺角亮邊）讓每格的繪製指令從 4 個增加到
    // 十幾個；20×20 的地圖每幀就是好幾千個指令，手機上會吃掉不少時間。
    // 但地磚層是**靜態的** —— 換圖才會變 —— 所以錄一次重播是安全的，
    // 細節多寡從此不影響每幀成本。點擊高亮與互動指標是動態的，留在外面。
    _groundPicture ??= _recordGround(data, halfW, halfH);
    canvas.drawPicture(_groundPicture!);

    _renderTappedCell(canvas, data, halfW, halfH);
    _renderInteractions(canvas, data, halfW, halfH);
  }

  /// 已錄製的地磚層；換圖時由 [_invalidateGround] 丟棄。
  ui.Picture? _groundPicture;

  ui.Picture _recordGround(IsoMapData data, double halfW, double halfH) {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    for (final layer in data.layers) {
      if (layer.type == 'collision') continue; // 碰撞為邏輯層，不繪製
      _renderLayer(c, layer, data, halfW, halfH);
    }
    return recorder.endRecording();
  }

  /// 丟棄地磚快取，下一幀重錄。地磚內容改變時必須呼叫。
  void _invalidateGround() {
    _groundPicture?.dispose();
    _groundPicture = null;
  }

  @override
  void onRemove() {
    _invalidateGround();
    super.onRemove();
  }

  /// 點擊格高亮：半透明紅色填滿菱形 + 紅描邊（tap 移動目標）。
  void _renderTappedCell(
      Canvas canvas, IsoMapData data, double halfW, double halfH) {
    final cell = _tappedCell;
    if (cell == null) return;
    final (tx, ty) = cell;
    if (!_inMap(data, tx, ty)) return;
    final sp = data.tileToScreen(tx, ty);
    final path = _cellPath(data, sp.x, sp.y);
    canvas.drawPath(path, Paint()..color = const Color(0x99E53935));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xE0FF5252)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  /// 一格的頂面路徑。**形狀由投影決定** —— 等距是菱形、俯視是方格。
  ///
  /// 角點一律向 [IsoMapData.cellCorners] 要，不在這裡再畫一份：
  /// 點擊高亮、格線、footprint 陰影都要同一個形狀，各畫一份的話
  /// 換投影就會漏改其中幾處。
  Path _cellPath(IsoMapData data, double topX, double topY) {
    final pts = data.cellCorners(topX, topY);
    final path = Path()..moveTo(pts.first.x, pts.first.y);
    for (final p in pts.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    return path..close();
  }

  /// 互動物件：常駐呼吸標記 + hover/走近時的類型動畫指標。
  void _renderInteractions(
      Canvas canvas, IsoMapData data, double halfW, double halfH) {
    if (data.interactables.isEmpty && _pending == null) return;

    final markerPhase = (_animClock * 0.6) % 1.0;
    for (final it in data.interactables) {
      final sp = data.tileToScreen(it.x, it.y);
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
      final sp = data.tileToScreen(active.x, active.y);
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

        final sp = data.tileToScreen(tx, ty);

        // 優先用伺服器指定的圖磚；沒有就退回程序化石板
        final serverTile = _serverTiles[(tx, ty)];
        if (serverTile != null) {
          _drawServerTile(canvas, serverTile, sp.x, sp.y, halfW, halfH);
          continue;
        }
        final ts = _findTileset(tileId, data);
        if (ts != null && _images.containsKey(ts.image)) {
          _drawSpriteTile(canvas, ts, tileId, sp.x, sp.y, halfW, halfH);
        } else {
          _drawFallbackTile(canvas, data, tx, ty, sp.x, sp.y, halfW, halfH);
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

  /// 畫一張伺服器指定的圖磚，貼滿該格的菱形外接矩形。
  void _drawServerTile(Canvas canvas, ui.Image img, double topX, double topY,
      double halfW, double halfH) {
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(topX - halfW, topY, halfW * 2, halfH * 2),
      Paint(),
    );
  }

  /// 通用石板地面：半透明、帶磨損（深淺、裂痕、缺角）。
  ///
  /// 維持半透明是必要的 —— 這層畫在 `_bgImage` 之上，有美術底圖的地圖
  /// （例如黑森林）要靠它透出來。細節見 [StoneFloor]。
  void _drawFallbackTile(Canvas canvas, IsoMapData data, int tx, int ty,
      double topX, double topY, double halfW, double halfH) {
    final path = _cellPath(data, topX, topY);
    StoneFloor.paintTile(canvas, path, tx, ty, topX, topY, halfW, halfH);
  }
}
