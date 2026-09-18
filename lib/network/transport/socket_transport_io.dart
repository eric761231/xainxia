import 'dart:io';

/// Native clients keep using the existing newline-delimited TCP protocol.
class SocketTransport {
  SocketTransport._(this._socket);
  final Socket _socket;

  static Future<SocketTransport> connect(
    String host,
    int port, {
    required Duration timeout,
  }) async {
    return SocketTransport._(
      await Socket.connect(host, port, timeout: timeout),
    );
  }

  Stream<List<int>> get incoming => _socket;
  void add(List<int> bytes) => _socket.add(bytes);
  Future<void> close() async {
    await _socket.close();
  }
}
