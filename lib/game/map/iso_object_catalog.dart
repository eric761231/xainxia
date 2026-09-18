import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 接地陰影的物件級覆寫。
///
/// 座標以格數表示；洞府與 [stone_floor.dart] 統一採上方光，故接地陰影預設置中。
/// 陰影幾何永遠由 footprint 組成，不會依 PNG 的透明邊界外擴。
@immutable
class ObjectShadowSpec {
  const ObjectShadowSpec({
    this.enabled = true,
    this.opacity = 0.20,
    this.blur = 4.0,
    this.offsetTilesX = 0,
    this.offsetTilesY = 0,
  });

  final bool enabled;
  final double opacity;
  final double blur;
  final double offsetTilesX;
  final double offsetTilesY;

  factory ObjectShadowSpec.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return const ObjectShadowSpec();
    final offset = raw['offsetTiles'] as List<dynamic>?;
    return ObjectShadowSpec(
      enabled: raw['enabled'] as bool? ?? true,
      opacity: ((raw['opacity'] as num?)?.toDouble() ?? 0.20)
          .clamp(0.0, 1.0)
          .toDouble(),
      blur: ((raw['blur'] as num?)?.toDouble() ?? 4.0)
          .clamp(0.0, 32.0)
          .toDouble(),
      offsetTilesX: (offset != null && offset.isNotEmpty)
          ? (offset[0] as num).toDouble()
          : 0,
      offsetTilesY: (offset != null && offset.length > 1)
          ? (offset[1] as num).toDouble()
          : 0,
    );
  }
}

/// 單一布置物件（prop）的美術與擺放定義（對應 object_catalog.json 內一個鍵）。
///
/// 兩種用法：
/// - **一檔一物件（最常見）**：省略 `src`/`anchor` → 用整張圖、腳底錨點取底邊中央。
///   ```jsonc
///   "1010": { "image": "tree001.png", "blocking": true, "label": "松樹" }
///   ```
/// - **atlas 打包**：給 `src` 裁切、`anchor` 指定腳底錨點（見 docs/map_pipeline.md §4）。
///   ```jsonc
///   "1002": { "image": "trees.png", "src": [0,0,128,192], "anchor": [64,180],
///             "footprint": [1,1], "blocking": true }
///   ```
///
/// `srcW/srcH`、`anchorX/anchorY` 為 null 時代表「未指定」，由渲染端依實際圖尺寸
/// 解析（w=圖寬、h=圖高、anchor=(w/2, h) 底邊中央）。
///
/// `dir`：圖片來源資料夾，`'objects'`（預設，assets/objects/）或 `'sences'`
/// （assets/sences/，讓場景圖也能當物件擺放）。
@immutable
class ObjectDef {
  const ObjectDef({
    required this.id,
    required this.image,
    required this.dir,
    required this.srcX,
    required this.srcY,
    required this.srcW,
    required this.srcH,
    required this.anchorX,
    required this.anchorY,
    required this.anchorMode,
    required this.footprintW,
    required this.footprintH,
    required this.blocking,
    this.shadow = const ObjectShadowSpec(),
    this.tilesW = 0,
    this.scale = 1.0,
    this.label = '',
  });

  final int id;
  final String image;

  /// 圖片來源資料夾（assets/ 底下）：`'objects'`（預設）/`'sences'`/`'tiles'`
  /// （讓場景圖、地形圖也能當物件擺放）。
  final String dir;

  /// atlas 內裁切矩形左上角 [x,y]（未指定 src 時為 0）。
  final double srcX;
  final double srcY;

  /// 裁切寬/高；null＝用整張圖（渲染端取 image.width/height）。
  final double? srcW;
  final double? srcH;

  /// 腳底錨點（相對裁切圖左上角，px）：渲染時此點對齊所在格中心。
  /// null＝依 [anchorMode] 由渲染端依實際圖尺寸解析。
  final double? anchorX;
  final double? anchorY;

  /// 錨點模式（僅在未指定數值 anchor 時生效）：
  /// - `'foot'`（預設）：站立物，錨點取底邊中央 (w/2, h)。
  /// - `'center'`：平貼物，錨點取圖中央 (w/2, h/2)。
  /// - `'tile'`：等距地形圖塊，錨點取 (w/2, 地圖半格高)，使圖塊頂點對齊格子頂點、
  ///   內部菱形線延續格網（需渲染端提供 mapHalfTileHeight）。
  final String anchorMode;

  /// 佔用格數（w,h），用於碰撞與放置。
  final int footprintW;
  final int footprintH;

  /// 是否阻擋行走（true → 載入時把 footprint 格設為不可走）。
  final bool blocking;

  /// 接地陰影規格；缺省時使用與地板一致的上方光置中接地陰影。
  final ObjectShadowSpec shadow;

  /// 預設視覺寬度（格數）：目標寬 = tilesW × 格寬，支援小數；0 = 原尺寸。
  ///
  /// <b>與 [footprintW] 是兩回事</b>：這是畫多大，footprint 是佔掉地面幾格。
  /// 美術素材常遠大於一格（例如 499px 的桌子 ≈ 7.8 格寬），
  /// 伺服器送來的場景物件沒有逐物件的尺寸覆寫，故以物件類型為單位在此設定。
  final double tilesW;

  /// 等比縮放倍率，套在 [tilesW] 之後；1 = 不縮放。錨點隨圖一起縮放，
  /// 所以腳底位置不變。只改「畫多大」，不影響 footprint 與碰撞。
  final double scale;

  /// 平貼地面的物件（法陣、地紋、等距地形塊）：一律畫在角色與家具之下。
  bool get isFlat => anchorMode != 'foot';

  /// 顯示名（編輯器 palette 用，可空）。
  final String label;

  /// 依實際裁切尺寸 (w,h) 解析腳底錨點：明確 anchor 優先，否則依 anchorMode。
  /// center → (w/2, h/2)（平貼）；tile → (w/2, mapHalfTileHeight)（等距地形，頂點對齊）；
  /// foot → (w/2, h)（站立）。
  (double, double) resolveAnchor(
    double w,
    double h, {
    double mapHalfTileHeight = 0,
  }) {
    final ax = anchorX ?? w / 2;
    final double ay;
    if (anchorY != null) {
      ay = anchorY!;
    } else {
      ay = switch (anchorMode) {
        'center' => h / 2,
        'tile' => mapHalfTileHeight,
        _ => h,
      };
    }
    return (ax, ay);
  }

  /// 圖片資料夾（assets/ 底下）。允許子資料夾（例如 `objects/black_forest`），
  /// 但根目錄只能是 objects / sences / tiles，且不接受 `..`；其餘一律退回 objects。
  ///
  /// 以前只認完整比對 `sences`/`tiles`，`objects/black_forest` 會被當成 `objects`
  /// → 到 assets/objects/ 找黑森林的圖 → 全部載不到、畫成綠色色塊。
  static String _parseDir(String? raw) {
    if (raw == null || raw.isEmpty || raw.contains('..') || raw.startsWith('/')) {
      return 'objects';
    }
    final dir = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    const roots = {'objects', 'sences', 'tiles'};
    return roots.contains(dir.split('/').first) ? dir : 'objects';
  }

  factory ObjectDef.fromJson(int id, Map<String, dynamic> j) {
    final srcRaw = j['src'] as List<dynamic>?;
    final src = srcRaw?.map((v) => (v as num).toDouble()).toList();
    final anchor = (j['anchor'] as List<dynamic>?)
        ?.map((v) => (v as num).toDouble())
        .toList();
    final fp = (j['footprint'] as List<dynamic>? ?? const [1, 1])
        .map((v) => (v as num).toInt())
        .toList();
    double? s(int i) => (src != null && i < src.length) ? src[i] : null;
    return ObjectDef(
      id: id,
      image: j['image'] as String? ?? '',
      dir: _parseDir(j['dir'] as String?),
      srcX: s(0) ?? 0,
      srcY: s(1) ?? 0,
      srcW: s(2), // null → 整張圖寬
      srcH: s(3), // null → 整張圖高
      anchorX: (anchor != null && anchor.isNotEmpty) ? anchor[0] : null,
      anchorY: (anchor != null && anchor.length > 1) ? anchor[1] : null,
      anchorMode: switch (j['anchorMode'] as String?) {
        'center' => 'center',
        'tile' => 'tile',
        _ => 'foot',
      },
      footprintW: fp.isNotEmpty ? fp[0] : 1,
      footprintH: fp.length > 1 ? fp[1] : 1,
      blocking: j['blocking'] as bool? ?? false,
      shadow: ObjectShadowSpec.fromJson(j['shadow']),
      tilesW: (j['tilesW'] as num?)?.toDouble() ?? 0,
      scale: switch ((j['scale'] as num?)?.toDouble()) {
        final double v when v > 0 => v,
        _ => 1.0,
      },
      label: j['label'] as String? ?? '',
    );
  }
}

/// 物件目錄：`assets/data/object_catalog.json` → id→[ObjectDef]。
///
/// 缺檔或格式錯誤時回空目錄（無物件也不崩潰）。載入結果快取。
class IsoObjectCatalog {
  IsoObjectCatalog._(this.defs);

  final Map<int, ObjectDef> defs;

  ObjectDef? operator [](int id) => defs[id];

  /// 依 id 排序的物件清單（供編輯器 palette）。
  List<ObjectDef> get all {
    final list = defs.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  static const _path = 'assets/data/object_catalog.json';
  static IsoObjectCatalog? _cache;

  /// 強制重新載入（編輯器改 catalog 後可呼叫）。
  static void invalidate() => _cache = null;

  static Future<IsoObjectCatalog> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final defs = <int, ObjectDef>{};
    try {
      final raw = await rootBundle.loadString(_path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final objects = json['objects'] as Map<String, dynamic>? ?? const {};
      objects.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is Map<String, dynamic>) {
          defs[id] = ObjectDef.fromJson(id, value);
        }
      });
    } catch (e) {
      debugPrint('IsoObjectCatalog: 讀不到 $_path（$e），改用空目錄');
    }
    return _cache = IsoObjectCatalog._(defs);
  }
}
