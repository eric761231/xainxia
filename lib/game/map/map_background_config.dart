import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 單張地圖底圖的對齊微調。
@immutable
class MapBackgroundOffset {
  const MapBackgroundOffset({this.offsetX = 0, this.offsetY = 0});

  /// 水平位移(px)，負值往左。
  final double offsetX;

  /// 垂直位移(px)，負值往上。
  final double offsetY;

  static const none = MapBackgroundOffset();

  factory MapBackgroundOffset.fromJson(Map<String, dynamic> j) =>
      MapBackgroundOffset(
        offsetX: (j['offsetX'] as num?)?.toDouble() ?? 0,
        offsetY: (j['offsetY'] as num?)?.toDouble() ?? 0,
      );
}

/// 地圖底圖對齊設定（`assets/data/map_backgrounds.json`）。
///
/// 底圖預設對齊可走區菱形的中心。但等距美術常含有牆面、高低差等「空間感」，
/// 圖中的地面菱形因此不在畫布幾何中心 —— 這種偏移量每張圖都不同，
/// 無法用單一公式推導，只能由美術端逐圖校正，故獨立成設定檔。
///
/// 換算：沿單一軸移動 1 格 = 垂直 16px；沿對角線移動 1 格 = 垂直 32px。
class MapBackgroundConfig {
  MapBackgroundConfig._();

  static const _path = 'assets/data/map_backgrounds.json';

  static Map<int, MapBackgroundOffset>? _cache;

  /// 清空快取（編輯器／熱重載重新讀取用）。
  static void clearCache() => _cache = null;

  static Future<Map<int, MapBackgroundOffset>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final result = <int, MapBackgroundOffset>{};
    try {
      final raw = await rootBundle.loadString(_path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final maps = json['maps'] as Map<String, dynamic>? ?? const {};
      maps.forEach((key, value) {
        final id = int.tryParse(key);
        if (id == null || value is! Map<String, dynamic>) return;
        result[id] = MapBackgroundOffset.fromJson(value);
      });
    } catch (e) {
      debugPrint('MapBackgroundConfig: 讀取 $_path 失敗（$e），全部不做位移');
    }
    return _cache = result;
  }

  /// 取得指定地圖的位移；未設定回傳零位移。
  static Future<MapBackgroundOffset> forMap(int mapId) async {
    final all = await load();
    return all[mapId] ?? MapBackgroundOffset.none;
  }
}
