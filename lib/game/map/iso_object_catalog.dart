import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// 顯示名（編輯器 palette 用，可空）。
  final String label;

  /// 依實際裁切尺寸 (w,h) 解析腳底錨點：明確 anchor 優先，否則依 anchorMode。
  /// center → (w/2, h/2)（平貼）；tile → (w/2, mapHalfTileHeight)（等距地形，頂點對齊）；
  /// foot → (w/2, h)（站立）。
  (double, double) resolveAnchor(double w, double h,
      {double mapHalfTileHeight = 0}) {
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
      dir: switch (j['dir'] as String?) {
        'sences' => 'sences',
        'tiles' => 'tiles',
        _ => 'objects',
      },
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
