import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// 連線設定 fallback（讀取 assets 失敗時使用）。
class ServerConfig {
  ServerConfig._();

  static const int protocolVersion = 1;
  static const String codec = 'plain';
  static const int connectTimeoutMs = 5000;
  static const int packetTimeoutMs = 10000;
  static const String defaultServerId = 'dev_local';
  /// JSON 內 dev 主機；Android 模擬器直連，其他平台由 [resolveDevHost] 改為本機。
  static const String fallbackHost = '10.0.2.2';
  static const int fallbackPort = 8080;
}

/// `10.0.2.2` 僅 Android 模擬器可對應本機；桌面／iOS 模擬器改為 127.0.0.1。
String resolveDevHost(String host) {
  if (host != ServerConfig.fallbackHost) {
    return host;
  }
  if (kIsWeb) {
    return '127.0.0.1';
  }
  if (Platform.isAndroid) {
    return ServerConfig.fallbackHost;
  }
  return '127.0.0.1';
}

ServerConnectionConfig _withResolvedDevHosts(ServerConnectionConfig config) {
  final gate = config.gate;
  final resolvedGate = gate == null
      ? null
      : GateEntry(
          host: resolveDevHost(gate.host),
          port: gate.port,
        );
  final servers = config.servers
      .map(
        (s) => ServerEntry(
          id: s.id,
          name: s.name,
          host: resolveDevHost(s.host),
          port: s.port,
          enabled: s.enabled,
        ),
      )
      .toList();
  return ServerConnectionConfig(
    protocolVersion: config.protocolVersion,
    codec: config.codec,
    connectTimeoutMs: config.connectTimeoutMs,
    packetTimeoutMs: config.packetTimeoutMs,
    defaultServerId: config.defaultServerId,
    servers: servers,
    gate: resolvedGate,
  );
}

/// Gate 伺服器（查詢各區狀態用，與 game server 登入分開）。
class GateEntry {
  const GateEntry({required this.host, required this.port});

  final String host;
  final int port;

  factory GateEntry.fromJson(Map<String, dynamic> json) {
    return GateEntry(
      host: json['host'] as String? ?? ServerConfig.fallbackHost,
      port: json['port'] as int? ?? ServerConfig.fallbackPort,
    );
  }
}

/// 單一伺服器連線設定。
class ServerEntry {
  const ServerEntry({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.enabled,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final bool enabled;

  factory ServerEntry.fromJson(Map<String, dynamic> json) {
    return ServerEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? ServerConfig.fallbackHost,
      port: json['port'] as int? ?? ServerConfig.fallbackPort,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// 通訊設定（由 assets/data/server_connection.json 載入）。
class ServerConnectionConfig {
  const ServerConnectionConfig({
    required this.protocolVersion,
    required this.codec,
    required this.connectTimeoutMs,
    required this.packetTimeoutMs,
    required this.defaultServerId,
    required this.servers,
    this.gate,
  });

  final int protocolVersion;
  final String codec;
  final int connectTimeoutMs;
  final int packetTimeoutMs;
  final String defaultServerId;
  final List<ServerEntry> servers;
  final GateEntry? gate;

  /// Gate 位址：優先 json.gate，否則 fallback 至 defaultServer。
  GateEntry? get gateEndpoint {
    if (gate != null) {
      return gate;
    }
    final server = defaultServer;
    if (server == null) {
      return null;
    }
    return GateEntry(host: server.host, port: server.port);
  }

  List<String> get enabledServerNames =>
      servers.where((s) => s.enabled).map((s) => s.name).toList();

  ServerEntry? findByName(String name) {
    for (final server in servers) {
      if (server.enabled && server.name == name) {
        return server;
      }
    }
    return null;
  }

  ServerEntry? get defaultServer {
    for (final server in servers) {
      if (server.enabled && server.id == defaultServerId) {
        return server;
      }
    }
    for (final server in servers) {
      if (server.enabled) {
        return server;
      }
    }
    return null;
  }

  factory ServerConnectionConfig.fallback() {
    return ServerConnectionConfig(
      protocolVersion: ServerConfig.protocolVersion,
      codec: ServerConfig.codec,
      connectTimeoutMs: ServerConfig.connectTimeoutMs,
      packetTimeoutMs: ServerConfig.packetTimeoutMs,
      defaultServerId: ServerConfig.defaultServerId,
      servers: const [
        ServerEntry(
          id: 'dev_local',
          name: '東勝神州',
          host: ServerConfig.fallbackHost,
          port: ServerConfig.fallbackPort,
          enabled: true,
        ),
      ],
    );
  }

  factory ServerConnectionConfig.fromJson(Map<String, dynamic> json) {
    final rawServers = json['servers'] as List<dynamic>? ?? [];
    final rawGate = json['gate'];
    return ServerConnectionConfig(
      protocolVersion:
          json['protocolVersion'] as int? ?? ServerConfig.protocolVersion,
      codec: json['codec'] as String? ?? ServerConfig.codec,
      connectTimeoutMs:
          json['connectTimeoutMs'] as int? ?? ServerConfig.connectTimeoutMs,
      packetTimeoutMs:
          json['packetTimeoutMs'] as int? ?? ServerConfig.packetTimeoutMs,
      defaultServerId:
          json['defaultServerId'] as String? ?? ServerConfig.defaultServerId,
      gate: rawGate is Map<String, dynamic>
          ? GateEntry.fromJson(rawGate)
          : null,
      servers: rawServers
          .map((e) => ServerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ServerConnectionLoader {
  static const _assetPath = 'assets/data/server_connection.json';

  static ServerConnectionConfig? _cached;

  static Future<ServerConnectionConfig> load() async {
    if (_cached != null) {
      return _cached!;
    }
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cached = _withResolvedDevHosts(ServerConnectionConfig.fromJson(json));
      return _cached!;
    } catch (_) {
      _cached = _withResolvedDevHosts(ServerConnectionConfig.fallback());
      return _cached!;
    }
  }
}
