@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/game_socket.dart';
import 'package:xianxia_game/network/codec/plain_text_codec.dart';

void main() {
  test(
    'native GameSocket sends TCP JSON and reports remote disconnect',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final accepted = server.first;
      final socket = GameSocket(PlainTextCodec());
      addTearDown(socket.dispose);
      addTearDown(server.close);
      await socket.connect(host: '127.0.0.1', port: server.port);
      final peer = await accepted;
      addTearDown(peer.destroy);
      final line = peer
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      socket.send({'op': 'test', 'text': '中文'});
      expect(jsonDecode(await line), {'op': 'test', 'text': '中文'});
      final lost = Completer<void>();
      socket.onConnectionLost = () => lost.complete();
      peer.destroy();
      await lost.future.timeout(const Duration(seconds: 3));
    },
  );
}
