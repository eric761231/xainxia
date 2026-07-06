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

/// 單一地圖圖層（data[row][col] = tileId，0 = 空）。
@immutable
class IsoTileLayer {
  const IsoTileLayer({required this.name, required this.data});

  final String name;
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
      data: raw
          .map((row) =>
              (row as List<dynamic>).map((v) => (v as num).toInt()).toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': 'tiles',
        'name': name,
        'data': data,
      };
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
  });

  final String id;
  final String name;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final List<IsoTileset> tilesets;
  final List<IsoTileLayer> layers;

  double get halfTileWidth => tileWidth / 2;
  double get halfTileHeight => tileHeight / 2;

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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        'tilesets': tilesets.map((t) => t.toJson()).toList(),
        'layers': layers.map((l) => l.toJson()).toList(),
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
