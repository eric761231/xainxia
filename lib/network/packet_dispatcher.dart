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
import 'packets/server/s_attack.dart';
import 'packets/server/s_hp_update.dart';
import 'packets/server/s_mp_update.dart';
import 'packets/server/s_dialog.dart';
import 'packets/server/s_bubble_dialog.dart';
import 'packets/server/s_gather_result.dart';
import 'packets/server/s_chat.dart';
import 'packets/server/s_gm_result.dart';
import 'packets/server/s_map_list.dart';
import 'packets/server/s_placeable_list.dart';
import 'packets/server/s_level_up_result.dart';
import 'packets/server/s_level_down_result.dart';
import 'packets/server/s_logout_result.dart';
import 'packets/server/s_login_result.dart';
import 'packets/server/s_map_change.dart';
import 'packets/server/s_map_collision.dart';
import 'packets/server/s_map_tiles.dart';
import 'packets/server/s_inventory.dart';
import 'packets/server/s_party.dart';
import 'packets/server/s_game_over.dart';
import 'packets/server/s_pc_pack.dart';
import 'packets/server/s_wave.dart';
import 'packets/server/s_map_info.dart';
import 'packets/server/s_npc_pack.dart';
import 'packets/server/s_monster_pack.dart';
import 'packets/server/s_property_pack.dart';
import 'packets/server/s_npc_move.dart';
import 'packets/server/s_property_update.dart';
import 'packets/server/s_object_remove.dart';
import 'packets/server/s_server_list.dart';
import 'packets/server/s_server_shutdown.dart';
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
typedef LevelDownResultHandler = void Function(SLevelDownResult result);
typedef CharStatsUpdateHandler = void Function(SCharStatsUpdate update);
typedef SystemMessageHandler = void Function(SSystemMessage message);
typedef GatherResultHandler = void Function(SGatherResult result);
typedef GmResultHandler = void Function(SGmResult result);
typedef ChatHandler = void Function(SChat chat);
typedef MapListHandler = void Function(SMapList list);
typedef PlaceableListHandler = void Function(SPlaceableList list);
typedef MapCollisionHandler = void Function(SMapCollision collision);
typedef MapTilesHandler = void Function(SMapTiles tiles);
typedef InventoryHandler = void Function(SInventory inventory);
typedef ItemUpdateHandler = void Function(SItemUpdate update);
typedef ItemRemoveHandler = void Function(SItemRemove remove);
typedef PartyHandler = void Function(SParty party);
typedef PartyInviteHandler = void Function(SPartyInvite invite);
typedef WaveHandler = void Function(SWave wave);
typedef GameOverHandler = void Function(SGameOver result);
typedef PcPackHandler = void Function(SPcPack pack);
typedef DialogHandler = void Function(SDialog dialog);
typedef BubbleDialogHandler = void Function(SBubbleDialog bubble);
typedef AttackHandler = void Function(SAttack attack);
typedef HpUpdateHandler = void Function(SHpUpdate update);
typedef MpUpdateHandler = void Function(SMpUpdate update);
typedef MapChangeHandler = void Function(SMapChange change);
typedef MapInfoHandler = void Function(SMapInfo info);
typedef NpcPackHandler = void Function(SNpcPack pack);
typedef MonsterPackHandler = void Function(SMonsterPack pack);
typedef PropertyPackHandler = void Function(SPropertyPack pack);
typedef NpcMoveHandler = void Function(SNpcMove move);
typedef PropertyUpdateHandler = void Function(SPropertyUpdate update);
typedef ObjectRemoveHandler = void Function(SObjectRemove remove);
typedef ServerShutdownHandler = void Function(SServerShutdown info);

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
  LevelDownResultHandler? onLevelDownResult;
  CharStatsUpdateHandler? onCharStatsUpdate;
  SystemMessageHandler? onSystemMessage;
  GatherResultHandler? onGatherResult;
  GmResultHandler? onGmResult;
  ChatHandler? onChat;
  MapListHandler? onMapList;
  PlaceableListHandler? onPlaceableList;
  MapCollisionHandler? onMapCollision;
  MapTilesHandler? onMapTiles;
  InventoryHandler? onInventory;
  ItemUpdateHandler? onItemUpdate;
  ItemRemoveHandler? onItemRemove;
  PartyHandler? onParty;
  PartyInviteHandler? onPartyInvite;
  WaveHandler? onWave;
  GameOverHandler? onGameOver;
  PcPackHandler? onPcPack;
  DialogHandler? onDialog;
  BubbleDialogHandler? onBubbleDialog;
  AttackHandler? onAttack;
  HpUpdateHandler? onHpUpdate;
  MpUpdateHandler? onMpUpdate;
  MapChangeHandler? onMapChange;
  MapInfoHandler? onMapInfo;
  NpcPackHandler? onNpcPack;
  MonsterPackHandler? onMonsterPack;
  PropertyPackHandler? onPropertyPack;
  NpcMoveHandler? onNpcMove;
  PropertyUpdateHandler? onPropertyUpdate;
  ObjectRemoveHandler? onObjectRemove;
  ServerShutdownHandler? onServerShutdown;

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
      case ServerOpcodes.sLevelDownResult:
        onLevelDownResult?.call(SLevelDownResult.fromData(packet.data));
        break;
      case ServerOpcodes.sCharStatsUpdate:
        onCharStatsUpdate?.call(SCharStatsUpdate.fromData(packet.data));
        break;
      case ServerOpcodes.sSystemMessage:
        onSystemMessage?.call(SSystemMessage.fromData(packet.data));
        break;
      case ServerOpcodes.sGatherResult:
        onGatherResult?.call(SGatherResult.fromData(packet.data));
        break;
      case ServerOpcodes.sGmResult:
        onGmResult?.call(SGmResult.fromData(packet.data));
        break;
      case ServerOpcodes.sChat:
        onChat?.call(SChat.fromData(packet.data));
        break;
      case ServerOpcodes.sMapList:
        onMapList?.call(SMapList.fromData(packet.data));
        break;
      case ServerOpcodes.sPlaceableList:
        onPlaceableList?.call(SPlaceableList.fromData(packet.data));
        break;
      case ServerOpcodes.sMapCollision:
        onMapCollision?.call(SMapCollision.fromData(packet.data));
        break;
      case ServerOpcodes.sMapTiles:
        onMapTiles?.call(SMapTiles.fromData(packet.data));
        break;
      case ServerOpcodes.sInventory:
        onInventory?.call(SInventory.fromData(packet.data));
        break;
      case ServerOpcodes.sItemUpdate:
        onItemUpdate?.call(SItemUpdate.fromData(packet.data));
        break;
      case ServerOpcodes.sItemRemove:
        onItemRemove?.call(SItemRemove.fromData(packet.data));
        break;
      case ServerOpcodes.sParty:
        onParty?.call(SParty.fromData(packet.data));
        break;
      case ServerOpcodes.sPartyInvite:
        onPartyInvite?.call(SPartyInvite.fromData(packet.data));
        break;
      case ServerOpcodes.sWave:
        onWave?.call(SWave.fromData(packet.data));
        break;
      case ServerOpcodes.sGameOver:
        onGameOver?.call(SGameOver.fromData(packet.data));
        break;
      case ServerOpcodes.sPcPack:
        onPcPack?.call(SPcPack.fromData(packet.data));
        break;
      case ServerOpcodes.sDialog:
        onDialog?.call(SDialog.fromData(packet.data));
        break;
      case ServerOpcodes.sBubbleDialog:
        onBubbleDialog?.call(SBubbleDialog.fromData(packet.data));
        break;
      case ServerOpcodes.sAttack:
        onAttack?.call(SAttack.fromData(packet.data));
        break;
      case ServerOpcodes.sHpUpdate:
        onHpUpdate?.call(SHpUpdate.fromData(packet.data));
        break;
      case ServerOpcodes.sMpUpdate:
        onMpUpdate?.call(SMpUpdate.fromData(packet.data));
        break;
      case ServerOpcodes.sMapChange:
        onMapChange?.call(SMapChange.fromData(packet.data));
        break;
      case ServerOpcodes.sMapInfo:
        onMapInfo?.call(SMapInfo.fromData(packet.data));
        break;
      case ServerOpcodes.sNpcPack:
        onNpcPack?.call(SNpcPack.fromData(packet.data));
        break;
      case ServerOpcodes.sMonsterPack:
        onMonsterPack?.call(SMonsterPack.fromData(packet.data));
        break;
      case ServerOpcodes.sPropertyPack:
        onPropertyPack?.call(SPropertyPack.fromData(packet.data));
        break;
      case ServerOpcodes.sNpcMove:
        onNpcMove?.call(SNpcMove.fromData(packet.data));
        break;
      case ServerOpcodes.sPropertyUpdate:
        onPropertyUpdate?.call(SPropertyUpdate.fromData(packet.data));
        break;
      case ServerOpcodes.sObjectRemove:
        onObjectRemove?.call(SObjectRemove.fromData(packet.data));
        break;
      case ServerOpcodes.sServerShutdown:
        onServerShutdown?.call(SServerShutdown.fromData(packet.data));
        break;
      default:
        debugPrint('未處理的 S 封包: ${packet.op}');
    }
  }
}
