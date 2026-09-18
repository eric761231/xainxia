import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/my_game.dart';
import 'package:xianxia_game/network/opcodes/client_opcodes.dart';
import 'package:xianxia_game/network/packets/client/c_chat.dart';
import 'package:xianxia_game/network/packets/server/s_chat.dart';
import 'package:xianxia_game/network/packets/server/s_map_list.dart';

/// 頻道代號必須與伺服器 ChatChannel 的 int 值逐一對應。
/// 對錯位的話不會拋例外，只會讓訊息跑到錯誤的頻道 —— 很難察覺。
void main() {
  group('ChatChannel', () {
    test('代號與伺服器一致', () {
      expect(ChatChannel.general.code, 0);
      expect(ChatChannel.world.code, 1);
      expect(ChatChannel.party.code, 2);
      expect(ChatChannel.guild.code, 3);
      expect(ChatChannel.whisper.code, 4);
      expect(ChatChannel.system.code, 5);
    });

    test('未知代號退回 system（不會被誤當成可發送頻道）', () {
      expect(ChatChannel.fromCode(99), ChatChannel.system);
      expect(ChatChannel.fromCode(-1), ChatChannel.system);
      expect(ChatChannel.fromCode(99).sendable, isFalse);
    });

    test('可發送頻道：世界／隊伍／門派／私聊', () {
      expect(ChatChannel.world.sendable, isTrue);
      expect(ChatChannel.party.sendable, isTrue);
      expect(ChatChannel.guild.sendable, isTrue);
      expect(ChatChannel.whisper.sendable, isTrue);
      // 綜合是檢視用、系統只由伺服器產生
      expect(ChatChannel.general.sendable, isFalse);
      expect(ChatChannel.system.sendable, isFalse);
    });
  });

  group('C_CHAT', () {
    test('帶頻道代號與私聊對象', () {
      final p = CChat.build(
          channel: ChatChannel.whisper, text: '哈囉', target: '蒼海');
      expect(p['op'], ClientOpcodes.cChat);
      expect(p['data'], {'channel': 4, 'text': '哈囉', 'target': '蒼海'});
    });

    test('非私聊時 target 為空字串', () {
      final p = CChat.build(channel: ChatChannel.world, text: '大家好');
      expect((p['data'] as Map)['target'], '');
      expect((p['data'] as Map)['channel'], 1);
    });
  });

  group('S_CHAT', () {
    test('解析一般訊息', () {
      final c = SChat.fromData(
          {'channel': 1, 'sender': '蒼海', 'text': '有人打副本嗎'});
      expect(c.channel, ChatChannel.world);
      expect(c.sender, '蒼海');
      expect(c.text, '有人打副本嗎');
    });

    test('系統訊息無發話者', () {
      final c =
          SChat.fromData({'channel': 5, 'sender': '', 'text': '「隊伍」頻道尚未實作'});
      expect(c.channel, ChatChannel.system);
      expect(c.sender, isEmpty);
    });

    test('缺欄位時不拋例外', () {
      final c = SChat.fromData({});
      expect(c.channel, ChatChannel.system);
      expect(c.text, isEmpty);
    });
  });

  group('S_MAP_LIST', () {
    test('解析地圖清單', () {
      final l = SMapList.fromData({
        'maps': [
          {'mapId': 0, 'name': '修練洞府'},
          {'mapId': 1, 'name': '黑森林'},
        ]
      });
      expect(l.maps, hasLength(2));
      expect(l.maps.first.mapId, 0);
      expect(l.maps.first.name, '修練洞府');
      expect(l.maps[1].name, '黑森林');
    });

    test('空清單不拋例外', () {
      expect(SMapList.fromData({}).maps, isEmpty);
    });
  });

  test('GM 權限門檻與伺服器一致（GmCommandHandler.REQUIRED_ACCESS_LEVEL）', () {
    expect(MyGame.gmAccessLevel, 100);
  });
}
