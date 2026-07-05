import 'package:flutter/foundation.dart';

import '../game/world_scene.dart';
import '../models/character_summary.dart';
import '../models/player_live_stats.dart';
import '../network/packet_dispatcher.dart';
import '../network/packets/client/c_breakthrough.dart';
import '../network/packets/client/c_gain_exp.dart';
import '../network/packets/server/s_breakthrough_result.dart';
import '../network/packets/server/s_char_stats_update.dart';
import '../network/packets/server/s_char_face.dart';
import '../network/packets/server/s_char_move.dart';
import '../network/packets/server/s_level_up_result.dart';
import '../network/packets/server/s_system_message.dart';
import 'game_session_service.dart';

/// 遊戲中封包 handler 接線（突破、升級、屬性同步、移動廣播、系統訊息）。
class GameWorldService {
  GameWorldService(this._session);

  final GameSessionService _session;

  final ValueNotifier<PlayerLiveStats?> liveStatsNotifier =
      ValueNotifier<PlayerLiveStats?>(null);
  final ValueNotifier<List<String>> systemMessagesNotifier =
      ValueNotifier<List<String>>([]);

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
      liveStatsNotifier.value =
          PlayerLiveStats.fromGameCharacter(initialCharacter);
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

  void _wireHandlers() {
    dispatcher.onBreakthroughResult = _onBreakthroughResult;
    dispatcher.onCharStatsUpdate = _onCharStatsUpdate;
    dispatcher.onLevelUpResult = _onLevelUpResult;
    dispatcher.onSystemMessage = _onSystemMessage;
    dispatcher.onCharMove = _onCharMove;
    dispatcher.onCharFace = _onCharFace;
  }

  void _unwireHandlers() {
    dispatcher.onBreakthroughResult = null;
    dispatcher.onCharStatsUpdate = null;
    dispatcher.onLevelUpResult = null;
    dispatcher.onSystemMessage = null;
    dispatcher.onCharMove = null;
    dispatcher.onCharFace = null;
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
    final charName = _activeCharName;
    if (charName == null) return;
    liveStatsNotifier.value =
        PlayerLiveStats.fromCharStatsUpdate(update, charName: charName);
  }

  void _onLevelUpResult(SLevelUpResult result) {
    if (result.success) {
      final current = liveStatsNotifier.value;
      if (current != null) {
        liveStatsNotifier.value = current.copyWith(
          realmLevel: result.realmLevel,
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
