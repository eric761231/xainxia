import 'dart:ui' show Rect;
import 'package:flame/components.dart' show Vector2;

import 'iso_coord.dart';

import 'package:flutter/foundation.dart';

/// 地圖圖集定義（sprite sheet）。
class IsoTileset {
  const IsoTileset({
    required this.firstId,
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    this.marginX = 0,
    this.marginY = 0,
    this.spacing = 0,
  });

  final int firstId;
  final String image;
  final int tileWidth;
  final int tileHeight;
  final int columns;

  /// 切片起點（第一格左上角距 sheet 左/上緣的 px），用來跳過額外物件列或留白邊距。
  final int marginX;
  final int marginY;

  /// 格與格之間的間隔 px（水平/垂直共用）。
  final int spacing;

  /// 第 [index]（0 起算）格在 sheet 上的來源矩形。
  Rect srcRect(int index) {
    final cols = columns < 1 ? 1 : columns;
    final col = index % cols;
    final row = index ~/ cols;
    return Rect.fromLTWH(
      (marginX + col * (tileWidth + spacing)).toDouble(),
      (marginY + row * (tileHeight + spacing)).toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
  }

  /// 依 tileId 取來源矩形（回退 firstId）。
  Rect srcRectForId(int tileId) => srcRect(tileId - firstId);

  factory IsoTileset.fromJson(Map<String, dynamic> json) => IsoTileset(
        firstId: json['firstId'] as int? ?? 1,
        image: json['image'] as String? ?? '',
        tileWidth: json['tileWidth'] as int? ?? 64,
        tileHeight: json['tileHeight'] as int? ?? 32,
        columns: json['columns'] as int? ?? 1,
        marginX: json['marginX'] as int? ?? 0,
        marginY: json['marginY'] as int? ?? 0,
        spacing: json['spacing'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'firstId': firstId,
        'image': image,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        'columns': columns,
        if (marginX != 0) 'marginX': marginX,
        if (marginY != 0) 'marginY': marginY,
        if (spacing != 0) 'spacing': spacing,
      };
}

/// 單一地圖圖層（data[row][col] = 值）。
///
/// type 'tiles'：值為 tileId（0=空）。
/// type 'collision'：值為碰撞（1=擋、0=可走）。
@immutable
class IsoTileLayer {
  const IsoTileLayer({
    required this.name,
    required this.data,
    this.type = 'tiles',
  });

  final String name;
  final String type;
  final List<List<int>> data;

  int tileAt(int tx, int ty) {
    if (ty < 0 || ty >= data.length) return 0;
    final row = data[ty];
    if (tx < 0 || tx >= row.length) return 0;
    return row[tx];
  }

  factory IsoTileLayer.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as List<dynamic>? ?? [];
    return IsoTileLayer(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'tiles',
      data: raw
          .map((row) =>
              (row as List<dynamic>).map((v) => (v as num).toInt()).toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'data': data,
      };
}

/// 地圖上的一個布置物件（prop）：把 [id]（對應 object_catalog.json）的美術
/// 擺在格 (x,y)。渲染時腳底對齊該格中心，並依腳底螢幕 y 與玩家一起深度排序，
/// 讓玩家能走到物件前方或後方（樹在屋後、花在門前）。
///
/// [zBias]：同腳底 y 的物件微調前後（正=更靠前/更晚畫）；預設 0。
/// [offsetX]/[offsetY]：逐物件像素微調（在錨點對齊格中心後再位移），用來精準對位。
/// [tilesW]：尺寸覆寫，目標寬＝tilesW×地圖格寬等比縮放；0＝原尺寸。
@immutable
class MapObject {
  const MapObject({
    required this.id,
    required this.x,
    required this.y,
    this.zBias = 0,
    this.offsetX = 0,
    this.offsetY = 0,
    this.tilesW = 0,
    this.layer = 1,
  });

  final int id;
  final int x;
  final int y;
  final int zBias;

  /// 所在圖層（1＝最底層）；跨層可在同格疊放，渲染時低層在下。
  final int layer;

  /// 逐物件像素微調（相對「錨點對齊格中心」再位移）；供在編輯器精準對位。
  final double offsetX;
  final double offsetY;

  /// 尺寸覆寫：目標寬度＝tilesW × 地圖格寬，支援半格等小數值。0＝原尺寸不縮放。
  final double tilesW;

  MapObject copyWith({
    int? id,
    int? x,
    int? y,
    int? zBias,
    double? offsetX,
    double? offsetY,
    double? tilesW,
    int? layer,
  }) =>
      MapObject(
        id: id ?? this.id,
        x: x ?? this.x,
        y: y ?? this.y,
        zBias: zBias ?? this.zBias,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
        tilesW: tilesW ?? this.tilesW,
        layer: layer ?? this.layer,
      );

  factory MapObject.fromJson(Map<String, dynamic> j) => MapObject(
        id: (j['id'] as num?)?.toInt() ?? 0,
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        zBias: (j['zBias'] as num?)?.toInt() ?? 0,
        offsetX: (j['offsetX'] as num?)?.toDouble() ?? 0,
        offsetY: (j['offsetY'] as num?)?.toDouble() ?? 0,
        tilesW: (j['tilesW'] as num?)?.toDouble() ?? 0,
        layer: (j['layer'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        if (zBias != 0) 'zBias': zBias,
        if (offsetX != 0) 'offsetX': offsetX,
        if (offsetY != 0) 'offsetY': offsetY,
        if (tilesW != 0) 'tilesW': tilesW,
        if (layer != 1) 'layer': layer,
      };
}

/// 出口/傳送點：站到 (x,y) 格 → 切換到地圖 toMap 的 (toX,toY)。
@immutable
class MapExit {
  const MapExit({
    required this.x,
    required this.y,
    required this.toMap,
    required this.toX,
    required this.toY,
  });

  final int x;
  final int y;
  final int toMap;
  final int toX;
  final int toY;

  MapExit copyWith({int? toMap, int? toX, int? toY}) => MapExit(
        x: x,
        y: y,
        toMap: toMap ?? this.toMap,
        toX: toX ?? this.toX,
        toY: toY ?? this.toY,
      );

  factory MapExit.fromJson(Map<String, dynamic> j) => MapExit(
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        toMap: (j['toMap'] as num?)?.toInt() ?? 0,
        toX: (j['toX'] as num?)?.toInt() ?? 0,
        toY: (j['toY'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'x': x, 'y': y, 'toMap': toMap, 'toX': toX, 'toY': toY};
}

/// 互動物件類型。
/// - portal：傳送門（樓梯／門），走近後本地切換地圖。
/// - gather：可採集資源（藥草／礦石）。
/// - talk：可對話／調查（NPC、物件）。
/// - attack：可攻擊目標。
enum InteractKind { portal, gather, talk, attack }

InteractKind _interactKindFromString(String? s) {
  switch (s) {
    case 'portal':
      return InteractKind.portal;
    case 'gather':
      return InteractKind.gather;
    case 'attack':
      return InteractKind.attack;
    case 'talk':
    default:
      return InteractKind.talk;
  }
}

/// 地圖上的互動物件：位在 (x,y) 格，玩家走到相鄰一格後可觸發。
///
/// 依 [kind] 使用不同欄位：
/// - portal：toMap/toX/toY（目標地圖與落點）。
/// - gather：resourceId（資源節點識別碼）。
/// - talk：npcId（對話對象）。
/// - attack：targetId（攻擊目標）。
@immutable
class MapInteractable {
  const MapInteractable({
    required this.x,
    required this.y,
    required this.kind,
    this.label = '',
    this.toMap,
    this.toX,
    this.toY,
    this.resourceId,
    this.npcId,
    this.targetId,
  });

  final int x;
  final int y;
  final InteractKind kind;

  /// 顯示名（tooltip 用，可空）。
  final String label;

  // portal
  final int? toMap;
  final int? toX;
  final int? toY;

  // gather
  final String? resourceId;

  // talk
  final int? npcId;

  // attack
  final int? targetId;

  bool get isPortal => kind == InteractKind.portal;

  MapInteractable copyWith({
    InteractKind? kind,
    String? label,
    int? toMap,
    int? toX,
    int? toY,
    String? resourceId,
    int? npcId,
    int? targetId,
  }) =>
      MapInteractable(
        x: x,
        y: y,
        kind: kind ?? this.kind,
        label: label ?? this.label,
        toMap: toMap ?? this.toMap,
        toX: toX ?? this.toX,
        toY: toY ?? this.toY,
        resourceId: resourceId ?? this.resourceId,
        npcId: npcId ?? this.npcId,
        targetId: targetId ?? this.targetId,
      );

  factory MapInteractable.fromJson(Map<String, dynamic> j) => MapInteractable(
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        kind: _interactKindFromString(j['type'] as String?),
        label: j['label'] as String? ?? '',
        toMap: (j['toMap'] as num?)?.toInt(),
        toX: (j['toX'] as num?)?.toInt(),
        toY: (j['toY'] as num?)?.toInt(),
        resourceId: j['resourceId'] as String?,
        npcId: (j['npcId'] as num?)?.toInt(),
        targetId: (j['targetId'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'x': x, 'y': y, 'type': kind.name};
    if (label.isNotEmpty) m['label'] = label;
    switch (kind) {
      case InteractKind.portal:
        m['toMap'] = toMap ?? 0;
        m['toX'] = toX ?? 0;
        m['toY'] = toY ?? 0;
        break;
      case InteractKind.gather:
        if (resourceId != null) m['resourceId'] = resourceId;
        break;
      case InteractKind.talk:
        if (npcId != null) m['npcId'] = npcId;
        break;
      case InteractKind.attack:
        if (targetId != null) m['targetId'] = targetId;
        break;
    }
    return m;
  }
}

/// 等距地圖完整資料。
@immutable
class IsoMapData {
  const IsoMapData({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.tilesets,
    required this.layers,
    this.background = '',
    this.originX = 0,
    this.originY = 0,
    this.renderScale = 1.0,
    this.exits = const [],
    this.interactables = const [],
    this.objects = const [],
    this.objectLayers = 1,
    this.characterLayer = 1,
    this.walkMinOverride,
    this.walkMaxOverride,
    this.projection = MapProjection.iso,
    this.coordOffset = 0,
  });

  /// 可走區的格座標範圍（generic 地圖在陣列外圍留了一圈不可走的邊界）。
  /// null = 整張陣列皆可走。僅執行期使用，不進 JSON ——
  /// 手工繪製的地圖以 collision 圖層為準。
  final int? walkMinOverride;
  final int? walkMaxOverride;

  /// 陣列索引 0 對應的地圖格座標。
  ///
  /// 伺服器的地圖邊界不一定從 0/1 開始（例如 31..50），若照座標值直接開陣列，
  /// 前面 31 排會變成純浪費的邊界格並被畫出來。故陣列只涵蓋實際範圍，
  /// 兩者以本欄位換算：`索引 = 座標 - coordOffset`。
  /// 手繪 JSON 地圖為 0（座標即索引）。
  final int coordOffset;

  /// 地圖座標 → 陣列索引。
  int toIndex(int mapCoord) => mapCoord - coordOffset;

  /// 陣列索引 → 地圖座標。
  int toMapCoord(int index) => index + coordOffset;

  /// 陣列涵蓋的最小／最大地圖座標（含邊界格）。
  int get minMapCoord => coordOffset;
  int get maxMapCoordX => coordOffset + width - 1;
  int get maxMapCoordY => coordOffset + height - 1;

  /// 可走區最小格座標（手繪地圖為 0）。
  int get walkMinCoord => walkMinOverride ?? 0;

  /// 可走區最大格座標（手繪地圖為 width-1）。
  int get walkMaxCoord => walkMaxOverride ?? (width - 1);

  /// 可走區邊長（格數）。
  int get walkSize => walkMaxCoord - walkMinCoord + 1;

  final String id;
  final String name;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;

  /// 這張地圖用哪種投影。**明確宣告，不從格尺寸推**（見 [MapProjection]）。
  /// 俯視地圖的格通常是正方，但「正方就是俯視」不成立 —— 1:1 等距也是正方。
  final MapProjection projection;

  final List<IsoTileset> tilesets;
  final List<IsoTileLayer> layers;

  /// 整張背景圖（單張場景）檔名（相對 assets/sences/）；空＝無背景圖、走 tile 渲染。
  final String background;

  /// 背景圖左上角在地圖 local 座標的位置，用來把等距格線對齊畫上的地板。
  final double originX;
  final double originY;

  /// 整張地圖視覺等比縮放（背景+格線+人物一起放大）；1.0=原尺寸。
  /// 僅影響渲染，不動 tile 座標／碰撞／傳送點邏輯。
  final double renderScale;

  /// 物件圖層數（1＝單層）；物件依 layer 由低到高疊，第 1 層為最底。
  final int objectLayers;

  /// 玩家所在圖層：低於它的圖層恆在玩家下、高於的恆在上、同層依腳底 y 深度排序。
  final int characterLayer;

  bool get hasBackground => background.isNotEmpty;

  double get halfTileWidth => tileWidth / 2;
  double get halfTileHeight => tileHeight / 2;

  // ── 投影：只有這裡知道要用哪一種 ──────────────────────────
  //
  // 呼叫端一律走這三個方法，不要自己呼叫 IsoCoord 並傳 projection ——
  // 全專案有 17 個呼叫點，逐一傳參數遲早會漏一個，而漏掉的那個會安靜地
  // 用等距畫在俯視地圖上。這個專案已經在「同一個量算兩次」上踩過很多次。

  /// 格 → 螢幕（格的上緣中點）。
  Vector2 tileToScreen(int tx, int ty) => IsoCoord.tileToScreen(
      tx, ty, halfTileWidth, halfTileHeight, projection: projection);

  /// 螢幕 → 格。
  (int, int) screenToTile(Vector2 pos) => IsoCoord.screenToTile(
      pos, halfTileWidth, halfTileHeight, projection: projection);

  /// 一格的四個角（等距是菱形、俯視是方格）。
  List<Vector2> cellCorners(double topX, double topY) => IsoCoord.cellCorners(
      topX, topY, halfTileWidth, halfTileHeight, projection: projection);

  /// 碰撞層（type=='collision'）；無則 null。
  IsoTileLayer? get collisionLayer {
    for (final l in layers) {
      if (l.type == 'collision') return l;
    }
    return null;
  }

  /// 該格是否被擋（1=擋）。無碰撞層時一律可走。
  /// 該格是否被擋住。參數為<b>地圖座標</b>，內部換算成陣列索引。
  bool isBlocked(int tx, int ty) =>
      collisionLayer?.tileAt(toIndex(tx), toIndex(ty)) == 1;

  /// 出口/傳送點清單。
  final List<MapExit> exits;

  /// 該格的出口（無則 null）。
  MapExit? exitAt(int tx, int ty) {
    for (final e in exits) {
      if (e.x == tx && e.y == ty) return e;
    }
    return null;
  }

  /// 互動物件清單（傳送門／採集／對話／攻擊）。
  final List<MapInteractable> interactables;

  /// 該格的互動物件（無則 null）。
  MapInteractable? interactableAt(int tx, int ty) {
    for (final i in interactables) {
      if (i.x == tx && i.y == ty) return i;
    }
    return null;
  }

  /// 傳送門清單（供小地圖顯示切換點）。
  List<MapInteractable> get portals =>
      interactables.where((i) => i.isPortal).toList();

  /// 布置物件（prop）清單：花草／建築等美術，依腳底深度與玩家排序。
  final List<MapObject> objects;

  factory IsoMapData.fromJson(Map<String, dynamic> json) {
    // layers 內 type=='objects' 的項是物件層（含 objects:[{id,x,y}]），
    // 其餘（tiles/collision）走 IsoTileLayer；把兩者分流。
    final rawLayers = json['layers'] as List<dynamic>? ?? [];
    final tileLayers = <IsoTileLayer>[];
    final objects = <MapObject>[];
    for (final l in rawLayers) {
      final m = l as Map<String, dynamic>;
      if (m['type'] == 'objects') {
        for (final o in (m['objects'] as List<dynamic>? ?? [])) {
          objects.add(MapObject.fromJson(o as Map<String, dynamic>));
        }
      } else {
        tileLayers.add(IsoTileLayer.fromJson(m));
      }
    }

    return IsoMapData(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        width: json['width'] as int? ?? 0,
        height: json['height'] as int? ?? 0,
        tileWidth: json['tileWidth'] as int? ?? 64,
        tileHeight: json['tileHeight'] as int? ?? 32,
        projection: (json['projection'] as String?) == 'topDown'
            ? MapProjection.topDown
            : MapProjection.iso,
        tilesets: (json['tilesets'] as List<dynamic>? ?? [])
            .map((t) => IsoTileset.fromJson(t as Map<String, dynamic>))
            .toList(),
        layers: tileLayers,
        objects: objects,
        background: json['background'] as String? ?? '',
        originX: (json['originX'] as num?)?.toDouble() ?? 0,
        originY: (json['originY'] as num?)?.toDouble() ?? 0,
        renderScale: (json['renderScale'] as num?)?.toDouble() ?? 1.0,
        exits: (json['exits'] as List<dynamic>? ?? [])
            .map((e) => MapExit.fromJson(e as Map<String, dynamic>))
            .toList(),
        interactables: (json['interactables'] as List<dynamic>? ?? [])
            .map((i) => MapInteractable.fromJson(i as Map<String, dynamic>))
            .toList(),
        objectLayers: (json['objectLayers'] as num?)?.toInt() ?? 1,
        characterLayer: (json['characterLayer'] as num?)?.toInt() ?? 1,
        // 座標空間。手繪地圖省略這三個欄位即可（座標＝索引、整張可走），
        // 但**伺服器地圖一定要寫**：它的格座標是 31..50，而陣列索引是 0..21。
        // 漏掉的話 coordOffset 會退回 0，toIndex(40) 算出 40 而不是 10 ——
        // 畫面、碰撞、與伺服器的座標會整組錯開 30 格。
        coordOffset: (json['coordOffset'] as num?)?.toInt() ?? 0,
        walkMinOverride: (json['walkMin'] as num?)?.toInt(),
        walkMaxOverride: (json['walkMax'] as num?)?.toInt(),
      );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'tileWidth': tileWidth,
        'projection':
            projection == MapProjection.topDown ? 'topDown' : 'iso',
        'tileHeight': tileHeight,
        // 座標空間：只在非預設時寫出，手繪地圖的 JSON 才不會多三個欄位
        if (coordOffset != 0) 'coordOffset': coordOffset,
        if (walkMinOverride != null) 'walkMin': walkMinOverride,
        if (walkMaxOverride != null) 'walkMax': walkMaxOverride,
        if (background.isNotEmpty) 'background': background,
        if (background.isNotEmpty) 'originX': originX,
        if (background.isNotEmpty) 'originY': originY,
        if (renderScale != 1.0) 'renderScale': renderScale,
        if (objectLayers != 1) 'objectLayers': objectLayers,
        if (characterLayer != 1) 'characterLayer': characterLayer,
        'tilesets': tilesets.map((t) => t.toJson()).toList(),
        'layers': [
          ...layers.map((l) => l.toJson()),
          if (objects.isNotEmpty)
            {
              'type': 'objects',
              'name': 'props',
              'objects': objects.map((o) => o.toJson()).toList(),
            },
        ],
        if (exits.isNotEmpty) 'exits': exits.map((e) => e.toJson()).toList(),
        if (interactables.isNotEmpty)
          'interactables': interactables.map((i) => i.toJson()).toList(),
      };

  /// 當地圖檔案不存在時使用的內建佔位地圖。
  static IsoMapData get placeholder => IsoMapData(
        id: 'placeholder',
        name: '佔位地圖',
        width: 12,
        height: 12,
        tileWidth: 64,
        tileHeight: 32,
        tilesets: const [],
        layers: [
          IsoTileLayer(
            name: 'ground',
            data: [
              [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
              [4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4],
              [4, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 4],
              [4, 1, 1, 3, 3, 2, 1, 1, 1, 1, 1, 4],
              [4, 1, 1, 3, 3, 2, 1, 1, 1, 1, 1, 4],
              [4, 1, 2, 2, 2, 2, 2, 2, 2, 1, 1, 4],
              [4, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 4],
              [4, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 4],
              [4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4],
              [4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4],
              [4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4],
              [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
            ],
          ),
        ],
      );

  /// 程式產生的通用地圖：灰格底版（零 PNG），對齊伺服器 `map` 表 bounds。
  /// 可走區＝座標 [minCoord]..[maxCoord]（含）方形（預設 31..50＝剛好 20×20 格）。
  /// 格陣列大小 = maxCoord+1（索引 0..maxCoord），使伺服器座標 k 直接對應索引 k，免偏移；
  /// 索引 < minCoord 的格為薄邊界（不可走、仍畫灰）。
  /// 遊戲端統一底版用（渲染統一灰、tap 紅格由 IsoMapComponent 處理）。
  /// 洞府地板圖集 `assets/tiles/ground_brick.png` 的排列。
  ///
  /// **這兩個值必須與圖檔一致**（512×64 = 8 欄 × 2 列）。圖集是 DrawPng 的
  /// `floor_brick_atlas` 產的，重產時若改了 `--count`／`--columns`，這裡要跟著改，
  /// 否則 `srcRect` 會取到圖外的空白，地板出現破洞。
  static const _groundAtlasColumns = 8;
  static const _groundAtlasCount = 16;

  /// 由格座標決定要用圖集裡的哪一格。
  ///
  /// 必須是**座標的函式**，不能用 `Random()` —— 每次重建地圖（進圖、換圖）
  /// 都會重新產生一次 layer，用亂數的話同一塊地板每次進來長得都不一樣，
  /// 而且與伺服器記錄的世界對不上。
  ///
  /// 整數雜湊，與 `stone_floor.dart` 同一套作法。
  static int _groundTileId(int x, int y) {
    var h = (x * 0x1F1F1F1F) ^ (y * 0x2545F491);
    h &= 0x7FFFFFFF;
    h ^= h >> 13;
    h = (h * 0x5BD1E995) & 0x7FFFFFFF;
    h ^= h >> 15;
    return 1 + (h % _groundAtlasCount);
  }

  /// 換掉地面層與圖集，其餘（尺寸、碰撞層、座標空間）原封不動。
  ///
  /// 給 `S_MAP_TILES` 用：伺服器只送地面，碰撞規則（外圈不可走）仍由
  /// [generic] 定義 —— 那條規則只該有一個地方寫。
  IsoMapData withGround({
    required List<IsoTileset> tilesets,
    required List<List<int>> ground,
  }) =>
      IsoMapData(
        id: id,
        name: name,
        width: width,
        height: height,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        tilesets: tilesets,
        layers: [
          IsoTileLayer(name: 'ground', data: ground),
          ...layers.where((l) => l.name != 'ground'),
        ],
        objects: objects,
        background: background,
        originX: originX,
        originY: originY,
        renderScale: renderScale,
        exits: exits,
        interactables: interactables,
        objectLayers: objectLayers,
        characterLayer: characterLayer,
        walkMinOverride: walkMinOverride,
        walkMaxOverride: walkMaxOverride,
        coordOffset: coordOffset,
      );

  static IsoMapData generic({
    int minCoord = 31,
    int maxCoord = 50,
    String name = '',
    int mapId = -1,
    // 格子尺寸也要能指定。伺服器的 maps/<id>.json 有 tileWidth/tileHeight，
    // 這裡若寫死 64×32 而圖磚是 48×24，畫的間距就比圖大三分之一 ——
    // 每一格之間會漏出底色，整片地板變成散開的碎片。
    int tileWidth = 64,
    int tileHeight = 32,
  }) {
    // 陣列涵蓋可走區再外擴一圈不可走邊界，讓前端在踏出範圍前就先停住。
    // 索引 0 對應座標 minCoord-1，故 coordOffset = minCoord - 1。
    final offset = minCoord - 1;
    final size = maxCoord - minCoord + 3;
    List<List<int>> gen(int Function(int x, int y) cell) => List.generate(
          size,
          (iy) => List.generate(size, (ix) => cell(ix + offset, iy + offset)),
        );
    bool walkable(int x, int y) =>
        x >= minCoord && x <= maxCoord && y >= minCoord && y <= maxCoord;

    final tilesets = <IsoTileset>[];
    if (mapId == 0) {
      // const 拿掉：格子尺寸現在是參數，不是編譯期常數。
      tilesets.add(IsoTileset(
        firstId: 1,
        // 洞府地板的後備圖集（8 欄 × 2 列）。實際鋪什麼由伺服器的
        // S_MAP_TILES 決定，這裡只是封包還沒到那幾幀的底版。
        image: 'ground_brick.png',
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        columns: _groundAtlasColumns,
      ));
    }

    return IsoMapData(
      id: 'generic',
      name: name,
      width: size,
      height: size,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      tilesets: tilesets,
      layers: [
        // 只畫可走區：外圈那圈邊界純粹是碰撞用（讓角色走到邊緣就停），
        // 若連它也畫出來，菱形會比底圖每邊各多一排（22 格 vs 20 格）。
        //
        // 有圖集時逐格挑一種變化 —— 整片鋪同一格會看出明顯的規律。
        // 沒有圖集的地圖仍給 1，走 _drawFallbackTile 的程序化石板。
        IsoTileLayer(
          name: 'ground',
          data: gen((x, y) => !walkable(x, y)
              ? 0
              : (tilesets.isEmpty ? 1 : _groundTileId(x, y))),
        ),
        IsoTileLayer(
          name: 'collision',
          type: 'collision',
          data: gen((x, y) => walkable(x, y) ? 0 : 1),
        ),
      ],
      // 洞府家具由伺服器的 property / spawnlist 資料生成，統一透過
      // S_PROPERTY_PACK 顯示。不能在這裡再放一份靜態物件，否則會重疊
      // 繪製，且前後端碰撞會不同步。
      walkMinOverride: minCoord,
      walkMaxOverride: maxCoord,
      coordOffset: offset,
    );
  }

  /// 通用地圖可走區中點座標（供出生點參考）；預設 31..50 → 40。
  static int genericCenter({int minCoord = 31, int maxCoord = 50}) =>
      (minCoord + maxCoord) ~/ 2;

  /// 該格是否在可走區（供渲染區分可走/邊界；等同 !isBlocked）。
  bool isWalkable(int tx, int ty) => !isBlocked(tx, ty);
}
