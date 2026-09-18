import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/map_background_config.dart';

/// 底圖校正位移是逐圖手調的資料，容易在改 JSON 時打錯而靜默失效
/// （欄位名錯 → 讀成 0 → 圖沒動，看起來像程式沒生效）。
///
/// 由 DrawPng 的 gen_map_base.py 產生的底圖天生對齊格網，不需要校正；
/// 只有手繪、含牆面／高低差的美術才需要在 map_backgrounds.json 設定。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(MapBackgroundConfig.clearCache);

  test('未設定的地圖回傳零位移，不是 null', () async {
    final o = await MapBackgroundConfig.forMap(0);
    expect(o.offsetX, 0.0);
    expect(o.offsetY, 0.0);
  });

  test('設定檔格式正確時能解析出位移', () {
    final o = MapBackgroundOffset.fromJson({'offsetX': 12, 'offsetY': -224});
    expect(o.offsetX, 12.0);
    expect(o.offsetY, -224.0);
  });

  test('欄位缺漏時退回 0 而非拋例外', () {
    final o = MapBackgroundOffset.fromJson({});
    expect(o.offsetX, 0.0);
    expect(o.offsetY, 0.0);
  });
}
