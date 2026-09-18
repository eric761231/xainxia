import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

@JS('WebSocket')
extension type _BrowserSocket._(JSObject _) implements JSObject {
  external factory _BrowserSocket(String url);
  external int get readyState;
  external void send(String data);
  external void close();
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type _MessageEvent._(JSObject _) implements JSObject {
  external JSAny? get data;
}

/// Text WebSocket frames carry the same UTF-8 JSON lines as native TCP.
class SocketTransport {
  SocketTransport._(this._socket);
  final _BrowserSocket _socket;
  final _incoming = StreamController<List<int>>();
  final _ready = Completer<void>();
  final Map<String, JSFunction> _listeners = {};
  bool _closed = false;

  static Future<SocketTransport> connect(
    String host,
    int port, {
    required Duration timeout,
  }) async {
    final uri = Uri(
      scheme: Uri.base.scheme == 'https' ? 'wss' : 'ws',
      host: host,
      port: port,
      path: '/ws',
    );
    final transport = SocketTransport._(_BrowserSocket(uri.toString()));
    transport._listen();
    try {
      await transport._ready.future.timeout(timeout);
      return transport;
    } catch (_) {
      await transport.close();
      rethrow;
    }
  }

  void _on(String name, void Function(JSObject) callback) {
    final listener = callback.toJS;
    _listeners[name] = listener;
    _socket.addEventListener(name, listener);
  }

  void _listen() {
    _on('open', (_) {
      if (!_ready.isCompleted) _ready.complete();
    });
    _on('message', (event) {
      final data = _MessageEvent._(event).data;
      if (data != null && data.isA<JSString>()) {
        final line = (data as JSString).toDart;
        _incoming.add(utf8.encode(line.endsWith('\n') ? line : '$line\n'));
      } else {
        _incoming.addError(StateError('伺服器必須傳送文字 WebSocket 封包'));
        unawaited(close());
      }
    });
    _on('error', (_) {
      final error = StateError('WebSocket 連線失敗，請確認伺服器支援 /ws');
      if (!_ready.isCompleted) {
        _ready.completeError(error);
      } else {
        _incoming.addError(error);
      }
      unawaited(close());
    });
    _on('close', (_) {
      if (!_ready.isCompleted) {
        _ready.completeError(StateError('WebSocket 握手完成前連線已關閉'));
      }
      unawaited(close());
    });
  }

  Stream<List<int>> get incoming => _incoming.stream;

  void add(List<int> bytes) {
    if (_closed || _socket.readyState != 1) {
      throw StateError('WebSocket 尚未連線或已關閉');
    }
    _socket.send(utf8.decode(bytes));
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final entry in _listeners.entries) {
      _socket.removeEventListener(entry.key, entry.value);
    }
    _listeners.clear();
    _socket.close();
    // A failed handshake may have no stream subscriber; do not await close.
    unawaited(_incoming.close());
  }
}
