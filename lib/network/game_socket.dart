import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'codec/packet_codec.dart';
import 'models/game_packet.dart';
// 遊戲 socket
class GameSocket {
  GameSocket(this._codec);
  final PacketCodec _codec;
  Socket? _socket; // 連接
  StreamSubscription<List<int>>? _subscription; // 訂閱
  final StreamController<GamePacket> _incomingController =
      StreamController<GamePacket>.broadcast(); // 接收封包

  Stream<GamePacket> get incoming => _incomingController.stream; // 接收封包

  // 連接
  Future<void> connect({
    required String host,
    required int port, // 埠
    Duration timeout = const Duration(seconds: 5), // 超時
  }) async {
    await disconnect(); // 斷開連接
    _codec.reset();
    // 連接
    _socket = await Socket.connect(host, port, timeout: timeout);
    _subscription = _socket!.listen(
      _onData, // 數據
      onError: _onError, // 錯誤
      onDone: _onDone, // 完成
      cancelOnError: true, // 錯誤時取消訂閱
    );
    debugPrint('GameSocket 已連線 $host:$port'); // 打印連接信息
  }

  // 發送封包
  void send(Map<String, dynamic> packet) {
    final socket = _socket;
    if (socket == null) {
      throw StateError('尚未連線，無法發送封包');
    }
    final jsonLine = jsonEncode(packet); // 編碼
    socket.add(_codec.encode(jsonLine));
    debugPrint('C包 → $jsonLine'); // 打印發送信息
  }

  // 斷開連接
  Future<void> disconnect() async {
    // 取消訂閱
    await _subscription?.cancel();
    _subscription = null; // 訂閱
    _codec.reset(); // 重置編解碼器
    try {
      await _socket?.close(); // 關閉連接
    } catch (_) {
      // ignore close errors // 忽略關閉錯誤
    }
    _socket = null; // 連接
  }

  // 數據
  void _onData(List<int> data) {
    var chunk = data;
    while (true) {
      final line = _codec.decode(chunk);
      if (line == null) {
        return;
      }
      chunk = const <int>[];
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final packet = GamePacket.fromJson(json);
        debugPrint('S包 ← $line');
        _incomingController.add(packet);
      } catch (e) {
        debugPrint('封包解析失敗: $line ($e)');
      }
    }
  }

  // 錯誤
  void _onError(Object error) {
    debugPrint('GameSocket 錯誤: $error');
    _incomingController.addError(error); // 添加錯誤
  }

  // 完成
  void _onDone() {
    debugPrint('GameSocket 連線關閉');
  }

  Future<void> dispose() async {
    await disconnect(); // 斷開連接
    await _incomingController.close(); // 關閉接收封包
  }
}
