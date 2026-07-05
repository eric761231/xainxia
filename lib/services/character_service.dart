import 'dart:async';

import '../config/server_connection_loader.dart';
import '../models/character_summary.dart';
import '../network/packets/client/c_char_list.dart';
import '../network/packets/client/c_create_char.dart';
import '../network/packets/client/c_delete_char.dart';
import '../network/packets/client/c_select_char.dart';
import '../network/packets/server/s_character_amount.dart';
import '../network/packets/server/s_character_list.dart';
import '../network/packets/server/s_create_char_result.dart';
import '../network/packets/server/s_delete_char_result.dart';
import '../network/packets/server/s_enter_game.dart';
import 'game_session_service.dart';

class CharacterResult {
  const CharacterResult({
    required this.success,
    required this.message,
    this.summary,
    this.enterGame,
  });

  final bool success;
  final String message;
  final CharacterListSummary? summary;
  final SEnterGame? enterGame;
}

/// 角色列表、創角、選角封包服務。
class CharacterService {
  CharacterService(this._session, this._connectionConfig);

  final GameSessionService _session;
  final ServerConnectionConfig _connectionConfig;

  CharacterListSummary? _cachedSummary;
  CharacterListSummary? get cachedSummary => _cachedSummary;

  void clearCache() {
    _cachedSummary = null;
  }

  Future<CharacterListSummary> fetchCharacterList() async {
    if (!_session.isConnected) {
      throw StateError('尚未連線，無法查詢角色列表');
    }

    SCharacterAmount? amount;
    SCharacterList? list;
    final completer = Completer<CharacterListSummary>();

    void tryComplete() {
      if (amount != null && list != null && !completer.isCompleted) {
        completer.complete(CharacterListSummary.fromPackets(amount!, list!));
      }
    }

    _session.dispatcher.onCharacterAmount = (value) {
      amount = value;
      tryComplete();
    };
    _session.dispatcher.onCharacterList = (value) {
      list = value;
      tryComplete();
    };

    try {
      _session.send(CCharList.build());
      final summary = await completer.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待角色列表逾時'),
      );
      _cachedSummary = summary;
      return summary;
    } finally {
      _session.dispatcher.onCharacterAmount = null;
      _session.dispatcher.onCharacterList = null;
    }
  }

  Future<CharacterResult> createCharacter({
    required String name,
    required int sex,
    required int attribute,
    required int statsIntel,
    required int statsSpirit,
    required int statsAgility,
    required int statsConstitution,
  }) async {
    if (!_session.isConnected) {
      return const CharacterResult(success: false, message: '尚未連線');
    }

    final createCompleter = Completer<SCreateCharResult>();
    final listCompleter = Completer<CharacterListSummary>();
    SCharacterAmount? amount;
    SCharacterList? list;

    void tryCompleteList() {
      if (amount != null && list != null && !listCompleter.isCompleted) {
        listCompleter.complete(CharacterListSummary.fromPackets(amount!, list!));
      }
    }

    _session.dispatcher.onCreateCharResult = (result) {
      if (!createCompleter.isCompleted) {
        createCompleter.complete(result);
      }
    };
    _session.dispatcher.onCharacterAmount = (value) {
      amount = value;
      tryCompleteList();
    };
    _session.dispatcher.onCharacterList = (value) {
      list = value;
      tryCompleteList();
    };

    try {
      _session.send(CCreateChar.build(
        name: name,
        sex: sex,
        attribute: attribute,
        statsIntel: statsIntel,
        statsSpirit: statsSpirit,
        statsAgility: statsAgility,
        statsConstitution: statsConstitution,
      ));

      final createResult = await createCompleter.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待創角結果逾時'),
      );

      if (!createResult.success) {
        return CharacterResult(
          success: false,
          message: createResult.message.isNotEmpty
              ? createResult.message
              : '創角失敗（${createResult.reason}）',
        );
      }

      final summary = await listCompleter.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待角色列表逾時'),
      );
      _cachedSummary = summary;
      return CharacterResult(
        success: true,
        message: createResult.message.isNotEmpty
            ? createResult.message
            : '角色建立成功',
        summary: summary,
      );
    } on TimeoutException catch (e) {
      return CharacterResult(
        success: false,
        message: e.message ?? '創角回應逾時',
      );
    } catch (e) {
      return CharacterResult(success: false, message: '創角失敗：$e');
    } finally {
      _session.dispatcher.onCreateCharResult = null;
      _session.dispatcher.onCharacterAmount = null;
      _session.dispatcher.onCharacterList = null;
    }
  }

  Future<CharacterResult> deleteCharacter(String name) async {
    if (!_session.isConnected) {
      return const CharacterResult(success: false, message: '尚未連線');
    }

    final deleteCompleter = Completer<SDeleteCharResult>();
    final listCompleter = Completer<CharacterListSummary>();
    SCharacterAmount? amount;
    SCharacterList? list;

    void tryCompleteList() {
      if (amount != null && list != null && !listCompleter.isCompleted) {
        listCompleter.complete(CharacterListSummary.fromPackets(amount!, list!));
      }
    }

    _session.dispatcher.onDeleteCharResult = (result) {
      if (!deleteCompleter.isCompleted) deleteCompleter.complete(result);
    };
    _session.dispatcher.onCharacterAmount = (value) {
      amount = value;
      tryCompleteList();
    };
    _session.dispatcher.onCharacterList = (value) {
      list = value;
      tryCompleteList();
    };

    try {
      _session.send(CDeleteChar.build(name: name));

      final deleteResult = await deleteCompleter.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待刪除結果逾時'),
      );

      if (!deleteResult.success) {
        return CharacterResult(
          success: false,
          message: deleteResult.message.isNotEmpty
              ? deleteResult.message
              : '刪除失敗（${deleteResult.reason}）',
        );
      }

      final summary = await listCompleter.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待角色列表逾時'),
      );
      _cachedSummary = summary;
      return CharacterResult(
        success: true,
        message: deleteResult.message.isNotEmpty ? deleteResult.message : '角色已刪除',
        summary: summary,
      );
    } on TimeoutException catch (e) {
      return CharacterResult(success: false, message: e.message ?? '刪除回應逾時');
    } catch (e) {
      return CharacterResult(success: false, message: '刪除失敗：$e');
    } finally {
      _session.dispatcher.onDeleteCharResult = null;
      _session.dispatcher.onCharacterAmount = null;
      _session.dispatcher.onCharacterList = null;
    }
  }

  Future<CharacterResult> selectCharacter(String name) async {
    if (!_session.isConnected) {
      return const CharacterResult(success: false, message: '尚未連線');
    }

    final completer = Completer<SEnterGame>();
    _session.dispatcher.onEnterGame = (result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    };

    try {
      _session.send(CSelectChar.build(name: name));
      final enterGame = await completer.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待進入遊戲逾時'),
      );
      return CharacterResult(
        success: true,
        message: '進入遊戲',
        enterGame: enterGame,
      );
    } on TimeoutException {
      return const CharacterResult(success: false, message: '進入遊戲逾時');
    } catch (e) {
      return CharacterResult(success: false, message: '選角失敗：$e');
    } finally {
      _session.dispatcher.onEnterGame = null;
    }
  }
}
