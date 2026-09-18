import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../game/world_scene.dart';
import '../models/game_character.dart';
import '../network/packet_dispatcher.dart';
import '../network/packets/client/c_breakthrough.dart';
import '../network/packets/client/c_gain_exp.dart';
import '../network/packets/client/c_chat.dart';
import '../network/packets/client/c_gm_command.dart';
import '../network/packets/client/c_place_property.dart';
import '../network/packets/server/s_breakthrough_result.dart';
import '../network/packets/server/s_char_stats_update.dart';
import '../network/packets/server/s_char_face.dart';
import '../network/packets/server/s_char_move.dart';
import '../network/packets/server/s_attack.dart';
import '../network/packets/server/s_hp_update.dart';
import '../network/packets/server/s_mp_update.dart';
import '../network/packets/server/s_bubble_dialog.dart';
import '../network/packets/server/s_level_down_result.dart';
import '../network/packets/server/s_dialog.dart';
import '../network/packets/server/s_gather_result.dart';
import '../network/packets/server/s_chat.dart';
import '../network/packets/server/s_gm_result.dart';
import '../network/packets/server/s_map_list.dart';
import '../network/packets/server/s_placeable_list.dart';
import '../network/packets/server/s_inventory.dart';
import '../network/packets/client/c_attack.dart';
import '../network/packets/client/c_challenge.dart';
import '../network/packets/client/c_party.dart';
import '../network/packets/client/c_item.dart';
import '../network/packets/server/s_level_up_result.dart';
import '../network/packets/server/s_system_message.dart';
import 'game_session_service.dart';

/// 遊戲中封包 handler 接線（突破、升級、屬性同步、移動廣播、系統訊息）。
class GameWorldService {
  GameWorldService(this._session);

  final GameSessionService _session;

  final ValueNotifier<GameCharacter?> liveStatsNotifier =
      ValueNotifier<GameCharacter?>(null);
  /// 背包內容。進遊戲時由 S_INVENTORY 整份填入，之後靠增量封包維護。
  ///
  /// 用 objId 當 key —— 同一種道具可能有多筆（不可疊加的武器），
  /// 以 itemId 當 key 會把它們併成一個。
  final ValueNotifier<Map<int, InventoryItem>> inventoryNotifier =
      ValueNotifier<Map<int, InventoryItem>>({});

  /// 聊天訊息（含系統訊息，系統訊息的 channel 為 [ChatChannel.system]）。
  final ValueNotifier<List<SChat>> chatMessagesNotifier =
      ValueNotifier<List<SChat>>([]);

  /// GM 指令輸出。刻意與聊天分離 —— GM 回饋不該洗版聊天頻道。
  final ValueNotifier<List<String>> gmLogNotifier =
      ValueNotifier<List<String>>([]);

  /// `.maps` 取得的地圖清單，供 GM 面板畫傳送列表。
  final ValueNotifier<List<MapListEntry>> mapListNotifier =
      ValueNotifier<List<MapListEntry>>([]);

  /// 可放置家具清單，供洞府布置面板使用。
  final ValueNotifier<List<PlaceableItem>> placeableNotifier =
      ValueNotifier<List<PlaceableItem>>([]);

  /// 最近一次收到的 NPC 對話（供對話視窗顯示；UI 待實作）。
  final ValueNotifier<SDialog?> dialogNotifier = ValueNotifier<SDialog?>(null);

  /// 最近一次收到的氣泡對話（顯示於物件頭上；UI 待實作）。
  final ValueNotifier<SBubbleDialog?> bubbleDialogNotifier =
      ValueNotifier<SBubbleDialog?>(null);

  /// 最近一次收到的攻擊演出（供傷害數字與動畫播放；演出待實作）。
  final ValueNotifier<SAttack?> attackNotifier = ValueNotifier<SAttack?>(null);

  /// 最近一次收到的血量更新（供血條顯示；UI 待實作）。
  final ValueNotifier<SHpUpdate?> hpUpdateNotifier =
      ValueNotifier<SHpUpdate?>(null);

  /// 最近一次收到的法力更新（自己與隊友；UI 待實作）。
  final ValueNotifier<SMpUpdate?> mpUpdateNotifier =
      ValueNotifier<SMpUpdate?>(null);


  String? _activeCharName;

  /// 自己的角色 objId。
  ///
  /// S_HP_UPDATE／S_MP_UPDATE 是**廣播**的（隊友的血量也會送來），
  /// 沒有這個就分不出哪一包是自己的，會拿隊友的血量去更新自己的 HUD。
  int _activeObjId = 0;
  WorldSceneComponent? _worldScene;

  PacketDispatcher get dispatcher => _session.dispatcher;

  void bindWorld({
    required String charName,
    required int charObjId,
    required WorldSceneComponent worldScene,
    GameCharacter? initialCharacter,
  }) {
    _activeCharName = charName;
    _activeObjId = charObjId;
    _worldScene = worldScene;
    if (initialCharacter != null) {
      liveStatsNotifier.value = initialCharacter;
    }
    _wireHandlers();
  }

  void unbind() {
    _unwireHandlers();
    _activeCharName = null;
    _activeObjId = 0;
    _worldScene = null;
    liveStatsNotifier.value = null;
    chatMessagesNotifier.value = const [];
    inventoryNotifier.value = {};
    gmLogNotifier.value = const [];
    mapListNotifier.value = const [];
    placeableNotifier.value = const [];
    dialogNotifier.value = null;
    bubbleDialogNotifier.value = null;
    attackNotifier.value = null;
    hpUpdateNotifier.value = null;
    mpUpdateNotifier.value = null;
  }

  /// 送出聊天訊息。[target] 僅私聊需要。
  void sendChat(ChatChannel channel, String text, {String target = ''}) {
    final content = text.trim();
    if (content.isEmpty) return;
    if (!channel.sendable) return;
    _session.send(
        CChat.build(channel: channel, text: content, target: target));
  }

  /// 請求可放置家具清單（開啟布置面板時送出）。
  void requestPlaceableList() {
    _session.send(CPlaceableList.build());
  }

  /// 放置一件家具。伺服器會驗證放置面規則與重疊，不合法時回系統訊息。
  void placeProperty(int propertyId, int x, int y) {
    _session.send(
        CPlaceProperty.build(propertyId: propertyId, x: x, y: y));
  }

  /// 移除一件自己的家具。
  void removeProperty(int objId) {
    _session.send(CRemoveProperty.build(objId: objId));
  }

  /// 搬動一件自己的家具到新座標。
  void moveProperty(int objId, int x, int y) {
    _session.send(CMoveProperty.build(objId: objId, x: x, y: y));
  }

  /// GM：設定單格地形是否可通行。伺服器改完會廣播給所有人。
  void setCollision(int x, int y, bool blocked) {
    _session.send(CGmCollision.build(x: x, y: y, blocked: blocked));
  }

  /// 送出 GM 指令（不含前綴的指令原文，例如 `tp 1 40 40`）。
  ///
  /// 供 GM 面板使用 —— 聊天輸入框不再處理 GM 指令，兩者已徹底分離。
  void sendGmCommand(String command) {
    final cmd = command.trim();
    if (cmd.isEmpty) return;
    _session.send(CGmCommand.build(command: cmd));
    _appendGmLog('> $cmd');
  }

  void sendBreakthrough() {
    _session.send(CBreakthrough.build());
  }

  void sendGainExp(int amount) {
    _session.send(CGainExp.build(amount: amount));
  }

  // ── 互動：走近互動物件後由 my_game 呼叫 ────────────────────────
  void _wireHandlers() {
    dispatcher.onBreakthroughResult = _onBreakthroughResult;
    dispatcher.onCharStatsUpdate = _onCharStatsUpdate;
    dispatcher.onLevelUpResult = _onLevelUpResult;
    dispatcher.onLevelDownResult = _onLevelDownResult;
    dispatcher.onSystemMessage = _onSystemMessage;
    dispatcher.onCharMove = _onCharMove;
    dispatcher.onCharFace = _onCharFace;
    dispatcher.onGatherResult = _onGatherResult;
    dispatcher.onGmResult = _onGmResult;
    dispatcher.onChat = _onChat;
    dispatcher.onMapList = _onMapList;
    dispatcher.onPlaceableList = _onPlaceableList;
    dispatcher.onDialog = _onDialog;
    dispatcher.onBubbleDialog = _onBubbleDialog;
    dispatcher.onAttack = _onAttack;
    dispatcher.onInventory = _onInventory;
    dispatcher.onItemUpdate = _onItemUpdate;
    dispatcher.onItemRemove = _onItemRemove;
    dispatcher.onHpUpdate = _onHpUpdate;
    dispatcher.onMpUpdate = _onMpUpdate;
  }

  void _unwireHandlers() {
    dispatcher.onBreakthroughResult = null;
    dispatcher.onCharStatsUpdate = null;
    dispatcher.onLevelUpResult = null;
    dispatcher.onLevelDownResult = null;
    dispatcher.onSystemMessage = null;
    dispatcher.onCharMove = null;
    dispatcher.onCharFace = null;
    dispatcher.onGatherResult = null;
    dispatcher.onGmResult = null;
    dispatcher.onChat = null;
    dispatcher.onMapList = null;
    dispatcher.onPlaceableList = null;
    dispatcher.onDialog = null;
    dispatcher.onBubbleDialog = null;
    dispatcher.onAttack = null;
    dispatcher.onInventory = null;
    dispatcher.onItemUpdate = null;
    dispatcher.onItemRemove = null;
    dispatcher.onHpUpdate = null;
    dispatcher.onMpUpdate = null;
  }

  void _onBreakthroughResult(SBreakthroughResult result) {
    if (result.success) {
      final current = liveStatsNotifier.value;
      if (current != null) {
        liveStatsNotifier.value = current.mergeBreakthrough(result);
      }
      _appendSystemMessage(result.message);
    } else {
      _appendSystemMessage(result.message);
    }
  }

  void _onCharStatsUpdate(SCharStatsUpdate update) {
    final current = liveStatsNotifier.value;
    if (current == null) return;
    liveStatsNotifier.value = current.applyStatsUpdate(update);
  }

  void _onLevelUpResult(SLevelUpResult result) {
    if (result.success) {
      final current = liveStatsNotifier.value;
      if (current != null) {
        liveStatsNotifier.value = current.copyWith(
          level: result.realmLevel,
          exp: result.exp,
          expMax: result.expMax,
        );
      }
      _appendSystemMessage(result.message);
    } else if (result.message.isNotEmpty) {
      _appendSystemMessage(result.message);
    }
  }

  void _onLevelDownResult(SLevelDownResult result) {
    if (result.success) {
      final current = liveStatsNotifier.value;
      if (current != null) {
        liveStatsNotifier.value = current.copyWith(
          level: result.realmLevel,
          exp: result.exp,
          expMax: result.expMax,
        );
      }
      _appendSystemMessage(result.message);
    } else if (result.message.isNotEmpty) {
      _appendSystemMessage(result.message);
    }
  }

  void _onSystemMessage(SSystemMessage message) {
    if (message.message.isNotEmpty) {
      _appendSystemMessage(message.message);
    }
  }

  void _onGatherResult(SGatherResult result) {
    if (result.success) {
      _appendSystemMessage(
          '採集成功：獲得${result.itemName} x${result.amount}');
    } else {
      _appendSystemMessage(
          result.message.isEmpty ? '採集失敗' : result.message);
    }
  }

  /// GM 指令結果：逐行進 GM 輸出區（.help 會是多行），不進聊天。
  void _onGmResult(SGmResult result) {
    for (final line in const LineSplitter().convert(result.message)) {
      if (line.trim().isEmpty) continue;
      _appendGmLog(line);
    }
  }

  void _onChat(SChat chat) {
    _appendChat(chat);
  }

  void _onMapList(SMapList list) {
    mapListNotifier.value = List.unmodifiable(list.maps);
  }

  void _onPlaceableList(SPlaceableList list) {
    placeableNotifier.value = List.unmodifiable(list.items);
  }

  void _onDialog(SDialog dialog) {
    dialogNotifier.value = dialog;
    final who = dialog.name.isEmpty ? '' : '${dialog.name}：';
    _appendSystemMessage('$who${dialog.text}');
  }

  void _onBubbleDialog(SBubbleDialog bubble) {
    bubbleDialogNotifier.value = bubble;
    final who = bubble.name.isEmpty ? '' : '${bubble.name}：';
    _appendSystemMessage('$who${bubble.text}');
  }

  void _onAttack(SAttack attack) {
    attackNotifier.value = attack;

    // S_ATTACK 是全場廣播，同一包也可能是別人打別人 —— 只播跟自己有關的兩種。
    // 從前一律印成「造成 X 傷害」，連怪物打自己都是這句，方向完全反了。
    final byMe = attack.attackerObjId == _activeObjId;
    final onMe = attack.targetObjId == _activeObjId;
    if (!byMe && !onMe) return;

    if (!attack.hit) {
      _appendSystemMessage(byMe ? '未命中' : '閃避了攻擊');
      return;
    }
    _appendSystemMessage(
        byMe ? '造成 ${attack.damage} 傷害' : '受到 ${attack.damage} 傷害');
  }

  // ── 背包 ──────────────────────────────────────────────────────────

  void _onInventory(SInventory inv) {
    inventoryNotifier.value = {
      for (final it in inv.items) it.objId: it,
    };
  }

  /// upsert：objId 已存在就更新，沒有就新增。
  ///
  /// 撿到新道具與數量改變共用同一個封包，所以這裡不分兩種情況。
  void _onItemUpdate(SItemUpdate update) {
    inventoryNotifier.value = {
      ...inventoryNotifier.value,
      update.item.objId: update.item,
    };
  }

  void _onItemRemove(SItemRemove remove) {
    final next = Map<int, InventoryItem>.from(inventoryNotifier.value)
      ..remove(remove.objId);
    inventoryNotifier.value = next;
  }

  // ── 隊伍 ──────────────────────────────────────────────────────────

  void partyInvite(String name) => _session.send(CParty.invite(name));
  void partyAccept() => _session.send(CParty.accept());
  void partyDecline() => _session.send(CParty.decline());
  void partyLeave() => _session.send(CParty.leave());
  void partyKick(String name) => _session.send(CParty.kick(name));
  void partyPromote(String name) => _session.send(CParty.promote(name));

  // ── 秘境挑戰 ──────────────────────────────────────────────────────

  /// 進入秘境。伺服器負責換圖與回滿血。
  void challengeEnter() => _session.send(CChallenge.enter());

  /// 還沒死就主動退出。死亡造成的退出不需要送 —— 伺服器自己會結算送人。
  void challengeLeave() => _session.send(CChallenge.leave());

  /// 攻擊目標。距離與合法性由伺服器判定。
  void attack(int targetObjId) =>
      _session.send(CAttack.build(targetObjId: targetObjId));

  /// 使用一件道具。伺服器會驗證是否可用，不合法時回系統訊息。
  void useItem(int objId) => _session.send(CUseItem.build(objId: objId));

  /// 丟棄一件道具。
  void dropItem(int objId, {int count = 1}) =>
      _session.send(CDropItem.build(objId: objId, count: count));

  /// 血量變化。
  ///
  /// 除了留給飄字／血條動畫用的 notifier，**還要回寫 liveStatsNotifier** ——
  /// 那是 HUD 顯示的來源。少了這一步，血條只有進圖那一瞬間是準的，
  /// 之後受傷補血都不會動。
  void _onHpUpdate(SHpUpdate update) {
    hpUpdateNotifier.value = update;
    if (update.objId != _activeObjId) return;   // 隊友的血量不動自己的 HUD
    final current = liveStatsNotifier.value;
    if (current == null) return;
    liveStatsNotifier.value =
        current.copyWith(hp: update.currentHp, hpMax: update.maxHp);
  }

  void _onMpUpdate(SMpUpdate update) {
    mpUpdateNotifier.value = update;
    if (update.objId != _activeObjId) return;
    final current = liveStatsNotifier.value;
    if (current == null) return;
    liveStatsNotifier.value =
        current.copyWith(mp: update.currentMp, mpMax: update.maxMp);
  }

  void _onCharMove(SCharMove move) {
    // 自己的那一包代表伺服器要強制修正本地位置。
    //
    // 目前伺服器對非法移動採「靜默拒絕」，不會走到這裡 —— 但這條路徑
    // 刻意保留，日後的強制位移（擊退、暈眩位移、劇情傳送）會直接用它。
    // 不是死碼，請勿當成殘留刪除。
    if (move.charName == _activeCharName) {
      _worldScene?.applySelfCorrection(move);
      return;
    }
    _worldScene?.applyRemoteMove(move);
  }

  void _onCharFace(SCharFace face) {
    if (face.charName == _activeCharName) return;
    _worldScene?.applyRemoteFace(face);
  }

  /// 本地系統訊息（不經伺服器）。
  ///
  /// 給尚未接上伺服器的 UI 動作用 —— 組隊／密語／寄信／驅逐這類按鈕
  /// 目前只有介面沒有功能，至少要讓玩家看到「按了有反應」。
  void localSystemMessage(String message) => _appendSystemMessage(message);

  /// 保留給既有呼叫端（升級、採集、攻擊…）：以系統頻道進聊天。
  void _appendSystemMessage(String message) {
    _appendChat(SChat(
        channel: ChatChannel.system, sender: '', text: message));
    debugPrint('[System] $message');
  }

  void _appendChat(SChat chat) {
    chatMessagesNotifier.value = _capped(
        List<SChat>.from(chatMessagesNotifier.value)..add(chat));
  }

  void _appendGmLog(String line) {
    gmLogNotifier.value =
        _capped(List<String>.from(gmLogNotifier.value)..add(line));
    debugPrint('[GM] $line');
  }

  /// 只保留最新 [_historyLimit] 則，避免長時間遊玩後無限增長。
  static const _historyLimit = 50;

  static List<T> _capped<T>(List<T> list) {
    if (list.length > _historyLimit) {
      list.removeRange(0, list.length - _historyLimit);
    }
    return list;
  }
}
