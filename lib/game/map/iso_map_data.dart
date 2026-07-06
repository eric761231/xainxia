import 'package:flutter/foundation.dart';

/// 地圖圖集定義（sprite sheet）。
class IsoTileset {
  const IsoTileset({
    required this.firstId,
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
  });

  final int firstId;
  final String image;
  final int tileWidth;
  final int tileHeight;
  final int columns;

  factory IsoTileset.fromJson(Map<String, dynamic> json) => IsoTileset(
        firstId: json['firstId'] as int? ?? 1,
        image: json['image'] as String? ?? '',
        tileWidth: json['tileWidth'] as int? ?? 64,
        tileHeight: json['tileHeight'] as int? ?? 32,
        columns: json['columns'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'firstId': firstId,
        'image': image,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        'columns': columns,
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
    this.exits = const [],
  });

  final String id;
  final String name;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final List<IsoTileset> tilesets;
  final List<IsoTileLayer> layers;

  /// 整張背景圖檔名（相對 assets/tiles/）；空＝無背景圖、走 tile 渲染。
  final String background;

  /// 背景圖左上角在地圖 local 座標的位置，用來把等距格線對齊畫上的地板。
  final double originX;
  final double originY;

  bool get hasBackground => background.isNotEmpty;

  double get halfTileWidth => tileWidth / 2;
  double get halfTileHeight => tileHeight / 2;

  /// 碰撞層（type=='collision'）；無則 null。
  IsoTileLayer? get collisionLayer {
    for (final l in layers) {
      if (l.type == 'collision') return l;
    }
    return null;
  }

  /// 該格是否被擋（1=擋）。無碰撞層時一律可走。
  bool isBlocked(int tx, int ty) => collisionLayer?.tileAt(tx, ty) == 1;

  /// 出口/傳送點清單。
  final List<MapExit> exits;

  /// 該格的出口（無則 null）。
  MapExit? exitAt(int tx, int ty) {
    for (final e in exits) {
      if (e.x == tx && e.y == ty) return e;
    }
    return null;
  }

  factory IsoMapData.fromJson(Map<String, dynamic> json) => IsoMapData(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        width: json['width'] as int? ?? 0,
        height: json['height'] as int? ?? 0,
        tileWidth: json['tileWidth'] as int? ?? 64,
        tileHeight: json['tileHeight'] as int? ?? 32,
        tilesets: (json['tilesets'] as List<dynamic>? ?? [])
            .map((t) => IsoTileset.fromJson(t as Map<String, dynamic>))
            .toList(),
        layers: (json['layers'] as List<dynamic>? ?? [])
            .map((l) => IsoTileLayer.fromJson(l as Map<String, dynamic>))
            .toList(),
        background: json['background'] as String? ?? '',
        originX: (json['originX'] as num?)?.toDouble() ?? 0,
        originY: (json['originY'] as num?)?.toDouble() ?? 0,
        exits: (json['exits'] as List<dynamic>? ?? [])
            .map((e) => MapExit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        if (background.isNotEmpty) 'background': background,
        if (background.isNotEmpty) 'originX': originX,
        if (background.isNotEmpty) 'originY': originY,
        'tilesets': tilesets.map((t) => t.toJson()).toList(),
        'layers': layers.map((l) => l.toJson()).toList(),
        if (exits.isNotEmpty) 'exits': exits.map((e) => e.toJson()).toList(),
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
}
