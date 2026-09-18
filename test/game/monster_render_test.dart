import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/game/map/iso_monster_component.dart';

/// 怪物元件的座標與血條。
///
/// 座標換算錯了不會拋例外 —— 怪物只是整批偏移 coordOffset 格（20 格以上），
/// 在畫面上看起來像「怪在牆外面」。這種錯誤只有量過才抓得到。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final data = IsoMapData.generic(minCoord: 31, maxCoord: 50, mapId: 0);

  IsoMonsterComponent make({
    int x = 40,
    int y = 41,
    int hp = 10,
    int max = 20,
  }) => createMonster(
    objId: 1,
    name: '山野狼',
    // 地圖座標直接傳 —— IsoPlayerComponent 這一族內部自己 toIndex
    x: x,
    y: y,
    facing: 2,
    maxHp: max,
    currentHp: hp,
    mapData: data,
  );

  group('座標空間', () {
    // IsoPlayerComponent 這一族（玩家／遠端玩家／怪物）吃地圖座標，
    // IsoObjectComponent（家具）吃陣列索引。在這裡多做一次 toIndex 的話，
    // 怪物會整批偏移 coordOffset 格 —— 不拋例外，只是全部跑到牆外面。
    test('伺服器的地圖座標原樣保留，不再換算一次', () {
      final m = make(x: 40, y: 41);
      expect(m.tileX, 40);
      expect(m.tileY, 41);
    });

    test('可走區的邊界值不會被 clamp 掉', () {
      expect(make(x: 31, y: 31).tileX, 31);
      expect(make(x: 50, y: 50).tileX, 50);
    });
  });

  group('伺服器推動位置', () {
    test('相鄰一格是用走的（保留原本的格子直到動畫走完）', () {
      final m = make(x: 40, y: 40);
      final before = m.tileX;
      m.applyServerPosition(41, 40, facing: 2);
      // moveTo 只設目標，要等 update 才會踏出去
      expect(m.tileX, before);
    });

    test('移動面向由實際位移決定，不採用錯誤的封包 heading', () {
      final m = make(x: 40, y: 40);
      m.applyServerPosition(41, 40, facing: 6);
      expect(m.facing, 2); // dx=+1, dy=0 => SE
    });

    test('怪物 walk 與一格移動共用 0..1 進度', () async {
      final m = make(x: 40, y: 40);
      await m.onLoad();
      m.applyServerPosition(41, 40, facing: 6);
      m.update(0);
      // 怪物走一格的時間跟著伺服器節奏，不是玩家的 0.4 秒
      m.update(m.stepSeconds / 2);

      expect(m.facing, 2);
      expect(m.spriteFacing, 2);
      expect(m.spriteFrame, 4);
    });

    // 以前固定 0.4 秒走完一格，伺服器卻每 0.8 秒才送下一格：怪物半路就停下、
    // 切回待機動作（低頭），看起來是「走一格、停一下、再走一格」。
    test('走一格的時間跟著伺服器實際的移動間隔', () {
      final m = make(x: 40, y: 40);
      for (var i = 1; i <= 6; i++) {
        m.applyServerPosition(40 + i, 40);
        m.update(0.6);
      }
      expect(m.measuredStepSeconds, closeTo(0.6, 0.05));
      expect(m.stepSeconds, m.measuredStepSeconds);
    });

    test('中間停過很久的間隔不算移動節奏', () {
      final m = make(x: 40, y: 40);
      final before = m.measuredStepSeconds;
      m.applyServerPosition(41, 40);
      m.update(5.0); // 怪物停了好幾秒才再走
      m.applyServerPosition(42, 40);
      expect(m.measuredStepSeconds, before);
    });

    test('走到定位後短暫維持走路動作，不會馬上閃回待機', () {
      final m = make(x: 40, y: 40);
      m.applyServerPosition(41, 40);
      m.update(0);
      m.update(m.stepSeconds); // 剛好走完一格
      expect(m.isMoving, isFalse);
      m.update(0.1);
      expect(m.walkAnimationActive, isTrue, reason: '下一包通常馬上就到');
      m.update(0.5);
      expect(m.walkAnimationActive, isFalse, reason: '真的停下來才切回待機');
    });

    // NPC 沿用怪物元件畫，靠這兩個能力：不畫血條、頭上說話
    test('NPC 模式不畫血條', () {
      final npc = createMonster(
        objId: 9,
        name: '守門童子',
        x: 40,
        y: 40,
        facing: 2,
        maxHp: 0,
        currentHp: 1,
        mapData: data,
        showHpBar: false,
      );
      expect(npc.showHpBar, isFalse);
      expect(make().showHpBar, isTrue, reason: '怪物預設照常畫血條');
    });

    test('頭上對話泡泡出現後，時間到就消失', () {
      final m = make(x: 40, y: 40);
      m.say('道友請留步');
      expect(m.bubbleText, '道友請留步');
      m.update(1.0);
      expect(m.bubbleText, '道友請留步');
      m.update(IsoMonsterComponent.bubbleSeconds);
      expect(m.bubbleText, isNull);
    });

    test('距離超過一格直接瞬移 —— 那代表傳送或不同步，用走的只是假動畫', () {
      final m = make(x: 40, y: 40);
      m.applyServerPosition(48, 33, facing: 5);
      expect(m.tileX, 48);
      expect(m.tileY, 33);
      expect(m.facing, 5);
    });
  });

  test('怪物名稱使用獨立高層文字元件顯示', () async {
    final m = createMonster(
      objId: 2,
      name: '測試怪物',
      x: 40,
      y: 40,
      facing: 2,
      maxHp: 10,
      currentHp: 10,
      mapData: data,
    );
    await m.onLoad();
    expect(m.hasVisibleName, isTrue);
  });

  group('血量', () {
    test('S_HP_UPDATE 會同時更新目前值與上限（波次每波加血）', () {
      final m = make(hp: 10, max: 20);
      m.applyHp(26, 40);
      expect(m.currentHp, 26);
      expect(m.maxHp, 40);
    });

    test('maxHp 傳 0 時保留原上限，不會把血條分母清成 0', () {
      final m = make(hp: 10, max: 20);
      m.applyHp(5, 0);
      expect(m.maxHp, 20);
      expect(m.currentHp, 5);
    });
  });

  test('本地碰撞圖不擋怪物 —— 牠的每一步伺服器已經驗過', () {
    expect(make().canEnter(0, 0), isTrue);
  });
}
