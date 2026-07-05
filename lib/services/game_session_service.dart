import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/server_connection_loader.dart';
import '../network/codec/codec_factory.dart';
import '../network/game_socket.dart';
import '../network/transport/game_packet.dart';
import '../network/packet_dispatcher.dart';

/// 登入成功後維持的遊戲 Socket 與封包監聽。
class GameSessionService {
  GameSessionService(this._connectionConfig);

  final ServerConnectionConfig _connectionConfig;
  final PacketDispatcher dispatcher = PacketDispatcher();

  GameSocket? _socket;
  StreamSubscription<GamePacket>? _subscription;

  GameSocket? get socket => _socket;
  bool get isConnected => _socket != null;

  bool _authenticated = false;
  bool get isAuthenticated => _authenticated;

  void markAuthenticated() {
    _authenticated = true;
  }

  void markUnauthenticated() {
    _authenticated = false;
  }

  Future<void> connect({
    required String host,
    required int port,
  }) async {
    await disconnect();
    _socket = GameSocket(CodecFactory.create(_connectionConfig.codec));
    await _socket!.connect(
      host: host,
      port: port,
      timeout: Duration(milliseconds: _connectionConfig.connectTimeoutMs),
    );
    _startListening();
  }

  void _startListening() {
    final socket = _socket;
    if (socket == null) {
      return;
    }
    _subscription?.cancel();
    _subscription = socket.incoming.listen(
      dispatcher.dispatch,
      onError: (Object error) {
        debugPrint('GameSession 封包流錯誤: $error');
      },
    );
  }

  void send(Map<String, dynamic> packet) {
    final socket = _socket;
    if (socket == null) {
      throw StateError('尚未連線，無法發送封包');
    }
    socket.send(packet);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _socket?.dispose();
    _socket = null;
    _authenticated = false;
  }
}
