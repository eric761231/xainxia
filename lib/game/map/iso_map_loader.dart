import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'iso_map_data.dart';

/// 從 `assets/maps/{mapId}.json` 讀取等距地圖資料。
class IsoMapLoader {
  IsoMapLoader._();

  static const _assetRoot = 'assets/maps/';

  static Future<IsoMapData> load(int mapId) async {
    final path = '$_assetRoot$mapId.json';
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return IsoMapData.fromJson(json);
    } catch (e) {
      debugPrint('IsoMapLoader: 無法載入地圖 $mapId ($e)，改用佔位地圖');
      return IsoMapData.placeholder;
    }
  }
}
