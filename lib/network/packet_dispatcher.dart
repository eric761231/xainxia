import 'package:flutter/foundation.dart';

import 'transport/game_packet.dart';
import 'opcodes/server_opcodes.dart';
import 'packets/server/s_character_amount.dart';
import 'packets/server/s_character_list.dart';
import 'packets/server/s_char_stats_update.dart';
import 'packets/server/s_create_char_result.dart';
import 'packets/server/s_delete_char_result.dart';
import 'packets/server/s_enter_game.dart';
import 'packets/server/s_breakthrough_result.dart';
import 'packets/server/s_char_face.dart';
import 'packets/server/s_char_move.dart';
import 'packets/server/s_level_up_result.dart';
import 'packets/server/s_logout_result.dart';
import 'packets/server/s_login_result.dart';
import 'packets/server/s_server_list.dart';
import 'packets/server/s_system_message.dart';

typedef LoginResultHandler = void Function(SLoginResult result);
typedef ServerListHandler = void Function(SServerList list);
typedef CharacterAmountHandler = void Function(SCharacterAmount amount);
typedef CharacterListHandler = void Function(SCharacterList list);
typedef CreateCharResultHandler = void Function(SCreateCharResult result);
typedef DeleteCharResultHandler = void Function(SDeleteCharResult result);
typedef EnterGameHandler = void Function(SEnterGame result);
typedef LogoutResultHandler = void Function(SLogoutResult result);
typedef CharMoveHandler = void Function(SCharMove move);
typedef CharFaceHandler = void Function(SCharFace face);
typedef BreakthroughResultHandler = void Function(SBreakthroughResult result);
typedef LevelUpResultHandler = void Function(SLevelUpResult result);
typedef CharStatsUpdateHandler = void Function(SCharStatsUpdate update);
typedef SystemMessageHandler = void Function(SSystemMessage message);

/// 依封包 [GamePacket.op] 分發到對應 handler。
class PacketDispatcher {
  LoginResultHandler? onLoginResult;
  ServerListHandler? onServerList;
  CharacterAmountHandler? onCharacterAmount;
  CharacterListHandler? onCharacterList;
  CreateCharResultHandler? onCreateCharResult;
  DeleteCharResultHandler? onDeleteCharResult;
  EnterGameHandler? onEnterGame;
  LogoutResultHandler? onLogoutResult;
  CharMoveHandler? onCharMove;
  CharFaceHandler? onCharFace;
  BreakthroughResultHandler? onBreakthroughResult;
  LevelUpResultHandler? onLevelUpResult;
  CharStatsUpdateHandler? onCharStatsUpdate;
  SystemMessageHandler? onSystemMessage;

  void dispatch(GamePacket packet) {
    switch (packet.op) {
      case ServerOpcodes.sServerList:
        onServerList?.call(SServerList.fromData(packet.data));
        break;
      case ServerOpcodes.sLoginResult:
        onLoginResult?.call(SLoginResult.fromData(packet.data));
        break;
      case ServerOpcodes.sLogoutResult:
        onLogoutResult?.call(SLogoutResult.fromData(packet.data));
        break;
      case ServerOpcodes.sCharacterAmount:
        onCharacterAmount?.call(SCharacterAmount.fromData(packet.data));
        break;
      case ServerOpcodes.sCharacterList:
        onCharacterList?.call(SCharacterList.fromData(packet.data));
        break;
      case ServerOpcodes.sCreateCharResult:
        onCreateCharResult?.call(SCreateCharResult.fromData(packet.data));
        break;
      case ServerOpcodes.sDeleteCharResult:
        onDeleteCharResult?.call(SDeleteCharResult.fromData(packet.data));
        break;
      case ServerOpcodes.sEnterGame:
        onEnterGame?.call(SEnterGame.fromData(packet.data));
        break;
      case ServerOpcodes.sCharMove:
        onCharMove?.call(SCharMove.fromData(packet.data));
        break;
      case ServerOpcodes.sCharFace:
        onCharFace?.call(SCharFace.fromData(packet.data));
        break;
      case ServerOpcodes.sBreakthroughResult:
        onBreakthroughResult?.call(SBreakthroughResult.fromData(packet.data));
        break;
      case ServerOpcodes.sLevelUpResult:
        onLevelUpResult?.call(SLevelUpResult.fromData(packet.data));
        break;
      case ServerOpcodes.sCharStatsUpdate:
        onCharStatsUpdate?.call(SCharStatsUpdate.fromData(packet.data));
        break;
      case ServerOpcodes.sSystemMessage:
        onSystemMessage?.call(SSystemMessage.fromData(packet.data));
        break;
      default:
        debugPrint('未處理的 S 封包: ${packet.op}');
    }
  }
}
