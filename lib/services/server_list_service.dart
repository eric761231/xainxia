import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/server_connection_loader.dart';
import '../models/server_status.dart';
import '../network/codec/codec_factory.dart';
import '../network/game_socket.dart';
import '../network/transport/game_packet.dart';
import '../network/packet_dispatcher.dart';
import '../network/packets/client/c_server_list.dart';
import '../network/packets/server/s_server_list.dart';

/// 向 Gate 查詢各伺服器即時狀態。
class ServerListService {
  ServerListService(this._connectionConfig);

  final ServerConnectionConfig _connectionConfig;
  List<ServerStatus> _statuses = [];

  List<ServerStatus> get statuses => List.unmodifiable(_statuses);

  ServerStatus? findByName(String name) {
    for (final status in _statuses) {
      if (status.name == name) {
        return status;
      }
    }
    return null;
  }

  /// 以本地設定建立預設列表（狀態為 unknown）。
  List<ServerStatus> buildFallbackStatuses() {
    return _connectionConfig.servers
        .where((s) => s.enabled)
        .map((e) => ServerStatus.fromEntry(e))
        .toList();
  }

  /// 連線 Gate → 發送 C_SERVER_LIST → 合併 S_SERVER_LIST 回應。
  Future<List<ServerStatus>> fetchStatuses() async {
    _statuses = buildFallbackStatuses();
    final gate = _connectionConfig.gateEndpoint;
    if (gate == null) {
      return _statuses;
    }

    final socket = GameSocket(CodecFactory.create(_connectionConfig.codec));
    final dispatcher = PacketDispatcher();
    StreamSubscription<GamePacket>? subscription;

    try {
      await socket.connect(
        host: gate.host,
        port: gate.port,
        timeout: Duration(milliseconds: _connectionConfig.connectTimeoutMs),
      );

      final completer = Completer<SServerList>();
      dispatcher.onServerList = (list) {
        if (!completer.isCompleted) {
          completer.complete(list);
        }
      };

      subscription = socket.incoming.listen(
        dispatcher.dispatch,
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      socket.send(CServerList.build());
      final remote = await completer.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待伺服器列表逾時'),
      );

      _statuses = _mergeRemote(remote);
      debugPrint('伺服器列表已更新：${_statuses.length} 個');
      return _statuses;
    } catch (e) {
      debugPrint('查詢伺服器列表失敗：$e');
      _statuses = _statuses
          .map((s) => s.copyWith(loadStatus: ServerLoadStatus.offline))
          .toList();
      return _statuses;
    } finally {
      dispatcher.onServerList = null;
      await subscription?.cancel();
      await socket.dispose();
    }
  }

  List<ServerStatus> _mergeRemote(SServerList remote) {
    final remoteById = <String, Map<String, dynamic>>{};
    for (final item in remote.servers) {
      final id = item['id'] as String?;
      if (id != null) {
        remoteById[id] = item;
      }
    }

    return _connectionConfig.servers.where((e) => e.enabled).map((entry) {
      final remoteItem = remoteById[entry.id];
      if (remoteItem == null) {
        return ServerStatus.fromEntry(entry);
      }
      return ServerStatus.fromRemote(remoteItem, entry);
    }).toList();
  }
}
