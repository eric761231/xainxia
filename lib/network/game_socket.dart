import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'codec/packet_codec.dart';
import 'transport/game_packet.dart';
import 'transport/socket_transport.dart';

// 遊戲 socket
class GameSocket {
  GameSocket(this._codec);
  final PacketCodec _codec;
  SocketTransport? _socket; // 連接
  StreamSubscription<List<int>>? _subscription; // 訂閱
  final StreamController<GamePacket> _incomingController =
      StreamController<GamePacket>.broadcast(); // 接收封包

  Stream<GamePacket> get incoming => _incomingController.stream; // 接收封包

  /// 連線被「對方（伺服器）」關閉或發生錯誤時觸發（含伺服器 -9／崩潰／正常關閉）。
  /// 客戶端主動 [disconnect] 會先取消訂閱，故不會觸發此回呼。只觸發一次。
  void Function()? onConnectionLost;
  bool _lostNotified = false;

  /// 除錯記錄單一封包最多印幾個字。
  static const int _logLimit = 2000;

  void _notifyLost() {
    if (_lostNotified) return;
    _lostNotified = true;
    onConnectionLost?.call();
  }

  // 連接
  Future<void> connect({
    required String host,
    required int port, // 埠
    Duration timeout = const Duration(seconds: 5), // 超時
  }) async {
    await disconnect(); // 斷開連接
    _lostNotified = false; // 新連線重置斷線旗標
    _codec.reset();
    // 連接
    _socket = await SocketTransport.connect(host, port, timeout: timeout);
    _subscription = _socket!.incoming.listen(
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
        // 大封包（上千筆場景物件、整張地圖的圖磚）整行印出來會拖慢主執行緒
        debugPrint(
          line.length > _logLimit
              ? 'S包 ← ${line.substring(0, _logLimit)}…（共 ${line.length} 字）'
              : 'S包 ← $line',
        );
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
    _notifyLost(); // 伺服器端連線異常（含 RST）→ 通知斷線
  }

  // 完成
  void _onDone() {
    debugPrint('GameSocket 連線關閉');
    _notifyLost(); // 伺服器端關閉連線（含 -9／崩潰／正常關閉）→ 通知斷線
  }

  Future<void> dispose() async {
    await disconnect(); // 斷開連接
    await _incomingController.close(); // 關閉接收封包
  }
}
