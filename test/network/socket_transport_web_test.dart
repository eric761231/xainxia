@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/transport/socket_transport.dart';

// Start the Java WebSocketEchoServer fixture before opting into this suite.
const _enabled = bool.fromEnvironment('WEBSOCKET_INTEGRATION');

void main() {
  group('browser WebSocket transport', () {
    test('round trips UTF-8 and large text and reconnects', () async {
      for (var attempt = 0; attempt < 2; attempt++) {
        final socket = await SocketTransport.connect(
          '127.0.0.1',
          18081,
          timeout: const Duration(seconds: 3),
        );
        final packets = StreamIterator(socket.incoming);
        final text = jsonEncode({'op': 'test', 'text': '中文修仙' * 2000});
        socket.add(utf8.encode('$text\n'));
        expect(await packets.moveNext(), isTrue);
        expect(utf8.decode(packets.current), '$text\n');
        await packets.cancel();
        await socket.close();
        expect(() => socket.add([10]), throwsStateError);
      }
    });

    test('remote close completes incoming stream', () async {
      final socket = await SocketTransport.connect(
        '127.0.0.1',
        18081,
        timeout: const Duration(seconds: 3),
      );
      final done = socket.incoming.drain<void>();
      socket.add(utf8.encode('__close__\n'));
      await done.timeout(const Duration(seconds: 3));
      await socket.close();
    });

    test('connection failure completes without hanging', () async {
      await expectLater(
        SocketTransport.connect(
          '127.0.0.1',
          18082,
          timeout: const Duration(seconds: 1),
        ),
        throwsA(anyOf(isA<StateError>(), isA<TimeoutException>())),
      );
    });
  }, skip: !_enabled);
}
