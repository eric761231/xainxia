import 'package:flutter/foundation.dart';

import '../game/map/iso_map_data.dart';
import '../game/world_scene.dart';
import '../models/game_character.dart';
import '../network/packet_dispatcher.dart';
import '../network/packets/client/c_breakthrough.dart';
import '../network/packets/client/c_gain_exp.dart';
import '../network/packets/client/c_gather.dart';
import '../network/packets/client/c_interact.dart';
import '../network/packets/client/c_use_skill.dart';
import '../network/packets/server/s_breakthrough_result.dart';
import '../network/packets/server/s_char_stats_update.dart';
import '../network/packets/server/s_char_face.dart';
import '../network/packets/server/s_char_move.dart';
import '../network/packets/server/s_combat_result.dart';
import '../network/packets/server/s_dialog.dart';
import '../network/packets/server/s_gather_result.dart';
import '../network/packets/server/s_level_up_result.dart';
import '../network/packets/server/s_system_message.dart';
import 'game_session_service.dart';

/// 遊戲中封包 handler 接線（突破、升級、屬性同步、移動廣播、系統訊息）。
class GameWorldService {
  GameWorldService(this._session);

  final GameSessionService _session;

  final ValueNotifier<GameCharacter?> liveStatsNotifier =
      ValueNotifier<GameCharacter?>(null);
  final ValueNotifier<List<String>> systemMessagesNotifier =
      ValueNotifier<List<String>>([]);

  /// 最近一次收到的 NPC 對話（供對話視窗顯示；UI 待實作）。
  final ValueNotifier<SDialog?> dialogNotifier = ValueNotifier<SDialog?>(null);

  /// 目前鎖定、待開技能選單的攻擊目標（供技能選單 UI；待實作）。
  final ValueNotifier<MapInteractable?> skillMenuTargetNotifier =
      ValueNotifier<MapInteractable?>(null);

  String? _activeCharName;
  WorldSceneComponent? _worldScene;

  PacketDispatcher get dispatcher => _session.dispatcher;

  void bindWorld({
    required String charName,
    required WorldSceneComponent worldScene,
    GameCharacter? initialCharacter,
  }) {
    _activeCharName = charName;
    _worldScene = worldScene;
    if (initialCharacter != null) {
      liveStatsNotifier.value = initialCharacter;
    }
    _wireHandlers();
  }

  void unbind() {
    _unwireHandlers();
    _activeCharName = null;
    _worldScene = null;
    liveStatsNotifier.value = null;
    systemMessagesNotifier.value = const [];
  }

  void sendBreakthrough() {
    _session.send(CBreakthrough.build());
  }

  void sendGainExp(int amount) {
    _session.send(CGainExp.build(amount: amount));
  }

  // ── 互動：走近互動物件後由 my_game 呼叫 ────────────────────────

  /// 依互動類型送出對應封包／開介面。
  void handleInteract(MapInteractable it) {
    switch (it.kind) {
      case InteractKind.portal:
        // 傳送門為本地切換，不經此處（WorldScene 已直接處理）。
        break;
      case InteractKind.gather:
        sendGather(it);
        break;
      case InteractKind.talk:
        sendInteract(it);
        break;
      case InteractKind.attack:
        openSkillMenu(it);
        break;
    }
  }

  /// 送出採集請求（C_GATHER），等待 S_GATHER_RESULT。
  void sendGather(MapInteractable it) {
    _session.send(
        CGather.build(x: it.x, y: it.y, resourceId: it.resourceId ?? ''));
    _appendSystemMessage('嘗試採集${it.label.isEmpty ? '' : '「${it.label}」'}…');
  }

  /// 送出互動／對話請求（C_INTERACT），等待 S_DIALOG。
  void sendInteract(MapInteractable it) {
    _session.send(CInteract.build(npcId: it.npcId ?? 0, x: it.x, y: it.y));
    _appendSystemMessage('與${it.label.isEmpty ? '對象' : '「${it.label}」'}交談…');
  }

  /// 開啟技能選單（純客戶端）。選定技能後由 [sendUseSkill] 送出攻擊。
  void openSkillMenu(MapInteractable it) {
    skillMenuTargetNotifier.value = it;
    _appendSystemMessage('鎖定${it.label.isEmpty ? '目標' : '「${it.label}」'}，開啟技能選單');
  }

  /// 送出技能施放（C_USE_SKILL），等待 S_COMBAT_RESULT。
  void sendUseSkill({required int skillId, required MapInteractable target}) {
    _session.send(CUseSkill.build(
        skillId: skillId,
        targetId: target.targetId ?? 0,
        x: target.x,
        y: target.y));
  }

  void _wireHandlers() {
    dispatcher.onBreakthroughResult = _onBreakthroughResult;
    dispatcher.onCharStatsUpdate = _onCharStatsUpdate;
    dispatcher.onLevelUpResult = _onLevelUpResult;
    dispatcher.onSystemMessage = _onSystemMessage;
    dispatcher.onCharMove = _onCharMove;
    dispatcher.onCharFace = _onCharFace;
    dispatcher.onGatherResult = _onGatherResult;
    dispatcher.onDialog = _onDialog;
    dispatcher.onCombatResult = _onCombatResult;
  }

  void _unwireHandlers() {
    dispatcher.onBreakthroughResult = null;
    dispatcher.onCharStatsUpdate = null;
    dispatcher.onLevelUpResult = null;
    dispatcher.onSystemMessage = null;
    dispatcher.onCharMove = null;
    dispatcher.onCharFace = null;
    dispatcher.onGatherResult = null;
    dispatcher.onDialog = null;
    dispatcher.onCombatResult = null;
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

  void _onDialog(SDialog dialog) {
    dialogNotifier.value = dialog;
    final who = dialog.npcName.isEmpty ? '' : '${dialog.npcName}：';
    _appendSystemMessage('$who${dialog.text}');
  }

  void _onCombatResult(SCombatResult result) {
    if (result.message.isNotEmpty) {
      _appendSystemMessage(result.message);
    } else {
      _appendSystemMessage(
          '造成 ${result.damage} 傷害${result.killed ? '，擊殺目標！' : ''}');
    }
  }

  void _onCharMove(SCharMove move) {
    if (move.charName == _activeCharName) return;
    _worldScene?.applyRemoteMove(move);
  }

  void _onCharFace(SCharFace face) {
    if (face.charName == _activeCharName) return;
    _worldScene?.applyRemoteFace(face);
  }

  void _appendSystemMessage(String message) {
    final list = List<String>.from(systemMessagesNotifier.value);
    list.add(message);
    if (list.length > 50) {
      list.removeRange(0, list.length - 50);
    }
    systemMessagesNotifier.value = list;
    debugPrint('[System] $message');
  }
}
