import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/party_member.dart';
import 'package:xianxia_game/network/packets/server/s_party.dart';
import 'package:xianxia_game/ui/widgets/shared/context_menu.dart';

void main() {
  group('PartyMember', () {
    PartyMemberData data({
      int objId = 10002,
      String name = '月蒼海',
      int hp = 50,
      int hpMax = 100,
      int mp = 25,
      int mpMax = 100,
    }) =>
        PartyMemberData.fromJson({
          'objId': objId,
          'name': name,
          'level': 12,
          'hp': hp,
          'hpMax': hpMax,
          'mp': mp,
          'mpMax': mpMax,
        });

    test('血量比例由 hp/maxHp 推導，並夾在 0..1', () {
      final m = PartyMember.fromPacket(data(),
          leaderObjId: 10002, selfObjId: 10002);
      expect(m.hpFraction, 0.5);
      expect(m.mpFraction, 0.25);
    });

    test('maxHp 為 0 時回 0 而非 NaN／無限大', () {
      // 直接算 hp/maxHp 會產生 NaN，畫進度條時會整個爆掉
      final m = PartyMember.fromPacket(data(hp: 0, hpMax: 0, mp: 0, mpMax: 0),
          leaderObjId: 0, selfObjId: 0);
      expect(m.hpFraction, 0);
      expect(m.mpFraction, 0);
    });

    test('隊長與自己由 objId 比對決定，不是成員資料的欄位', () {
      final me = PartyMember.fromPacket(data(objId: 10002),
          leaderObjId: 10002, selfObjId: 10002);
      expect(me.isLeader, isTrue);
      expect(me.isSelf, isTrue);

      final other = PartyMember.fromPacket(data(objId: 20001, name: '洛清塵'),
          leaderObjId: 10002, selfObjId: 10002);
      expect(other.isLeader, isFalse);
      expect(other.isSelf, isFalse,
          reason: '別人那列才會出現「驅逐」');
    });
  });

  group('S_PARTY', () {
    test('整包解析，隊長標記正確', () {
      final p = SParty.fromData({
        'partyId': 1,
        'leaderObjId': 10002,
        'members': [
          {'objId': 10002, 'name': '月蒼海', 'level': 12,
           'hp': 200, 'hpMax': 200, 'mp': 100, 'mpMax': 100},
          {'objId': 20001, 'name': '洛清塵', 'level': 9,
           'hp': 80, 'hpMax': 150, 'mp': 40, 'mpMax': 90},
        ],
      });
      expect(p.members, hasLength(2));
      expect(p.leaderObjId, 10002);
      expect(p.isEmpty, isFalse);
    });

    test('成員為空＝已離隊或解散，前端據此清空隊伍欄', () {
      expect(SParty.fromData({'members': []}).isEmpty, isTrue);
      expect(SParty.fromData({}).isEmpty, isTrue);
    });
  });

  group('S_PARTY_INVITE', () {
    test('帶邀請者名稱', () {
      final i = SPartyInvite.fromData(
          {'inviterObjId': 10002, 'inviterName': '月蒼海'});
      expect(i.inviterName, '月蒼海');
    });
  });

  group('右鍵選單定位', () {
    // 選單靠近畫面邊緣時必須往內翻，否則手機上會被切掉一半
    const screen = Size(952, 426);
    const menuW = 132.0;
    const margin = 8.0;

    double clampLeft(double x, double w) {
      var left = x;
      if (left + w + margin > screen.width) left = screen.width - w - margin;
      return left.clamp(margin, screen.width - w - margin);
    }

    double clampTop(double y, double h) {
      var top = y;
      if (top + h + margin > screen.height) top = screen.height - h - margin;
      return top.clamp(margin, screen.height - h - margin);
    }

    test('畫面中央：位置不變', () {
      expect(clampLeft(400, menuW), 400);
      expect(clampTop(200, 120), 200);
    });

    test('貼右緣：往左翻，整個選單仍在畫面內', () {
      final left = clampLeft(940, menuW);
      expect(left + menuW + margin, lessThanOrEqualTo(screen.width));
    });

    test('貼下緣：往上翻，整個選單仍在畫面內', () {
      final top = clampTop(420, 120);
      expect(top + 120 + margin, lessThanOrEqualTo(screen.height));
    });

    test('負座標被夾回邊界內', () {
      expect(clampLeft(-50, menuW), margin);
      expect(clampTop(-50, 120), margin);
    });
  });

  group('ContextMenuRequest', () {
    test('保留標題與項目順序', () {
      final req = ContextMenuRequest(
        position: const Offset(10, 20),
        title: '墨無痕',
        items: [
          ContextMenuItem('委任隊長', () {}),
          ContextMenuItem('驅逐隊員', () {}, danger: true),
        ],
      );
      expect(req.title, '墨無痕');
      expect(req.items.map((i) => i.label), ['委任隊長', '驅逐隊員']);
      expect(req.items.last.danger, isTrue);
      expect(req.items.first.danger, isFalse);
    });
  });

  group('生命條與菱形的咬合幾何', () {
    // 這組數字決定 HP/MP 的 V 形凹口能不能與菱形斜邊嚴絲合縫。
    // 任何一個常數被改動而沒有一起調整，接縫處就會露出背景或互相重疊。
    const barWidth = 560.0;
    const diamond = 60.0;
    const notch = diamond / 2;

    // Row 裡兩個 Expanded 等分寬度
    const sideW = barWidth / 2;
    // Stack 置中 → 菱形水平中心就是整條的中心
    const diamondCenterX = barWidth / 2;
    const diamondLeftVertexX = diamondCenterX - diamond / 2;
    const diamondRightVertexX = diamondCenterX + diamond / 2;

    test('HP 的凹口頂點正好落在菱形的左頂點', () {
      // HP 佔 [0, sideW]，凹口頂點在右端往左縮 notch
      const apexX = sideW - notch;
      expect(apexX, diamondLeftVertexX);
    });

    test('MP 的凹口頂點正好落在菱形的右頂點', () {
      // MP 佔 [sideW, barWidth]，凹口頂點在左端往右推 notch
      const apexX = sideW + notch;
      expect(apexX, diamondRightVertexX);
    });

    test('兩條在菱形中心線相接，中間沒有間隙', () {
      // 留間隙的話接縫處會露出背景色
      expect(sideW, diamondCenterX);
    });

    test('凹口深度等於半條高，斜邊才會是 45 度（與菱形一致）', () {
      const barH = diamond;
      expect(notch, barH / 2);
    });
  });

  group('小地圖尺寸：不得超出畫面下緣', () {
    // 對應 GameHudOverlay 裡的計算。寫成測試是因為這牽涉四個常數，
    // 任何一個被改動都可能讓小地圖在手機上又被切掉。
    const designW = 1920.0, designH = 1080.0;
    const boost = 1.1, cell = 46.0, gap = 4.0;
    const minSize = 120.0, maxSize = 220.0;

    ({double size, double columnH}) layout(double w, double h) {
      final scale = (w / designW < h / designH ? w / designW : h / designH)
          .clamp(0.45, 1.4);
      final colScale = scale * boost;
      final reserved = (34 + gap * 3 + cell * 2) * colScale;
      final size = ((h - reserved) / colScale).clamp(minSize, maxSize);
      // 整欄實際佔用的高度（含小地圖與兩排快捷鈕）
      final columnH = (34 + gap * 3 + cell * 2 + size) * colScale;
      return (size: size, columnH: columnH);
    }

    test('桌機 1920x1080：維持最大直徑', () {
      expect(layout(1920, 1080).size, maxSize);
    });

    test('Pixel 9 Pro 橫向 952x426：整欄仍在畫面內', () {
      final r = layout(952, 426);
      expect(r.columnH, lessThanOrEqualTo(426));
    });

    test('極端矮視窗 800x300：縮到下限，且不會變成負值', () {
      final r = layout(800, 300);
      expect(r.size, greaterThanOrEqualTo(minSize));
      expect(r.size, lessThanOrEqualTo(maxSize));
    });

    test('直徑永遠落在上下限之間', () {
      for (final h in [200.0, 300.0, 426.0, 600.0, 1080.0, 1440.0]) {
        final size = layout(1920, h).size;
        expect(size, inInclusiveRange(minSize, maxSize), reason: 'h=$h');
      }
    });
  });
}
