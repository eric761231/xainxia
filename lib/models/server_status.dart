import '../config/server_connection_loader.dart';

enum ServerLoadStatus {
  smooth,
  crowded,
  full,
  maintenance,
  offline,
  unknown;

  static ServerLoadStatus fromString(String? value) {
    switch (value) {
      case 'smooth':
        return ServerLoadStatus.smooth;
      case 'crowded':
        return ServerLoadStatus.crowded;
      case 'full':
        return ServerLoadStatus.full;
      case 'maintenance':
        return ServerLoadStatus.maintenance;
      case 'offline':
        return ServerLoadStatus.offline;
      default:
        return ServerLoadStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case ServerLoadStatus.smooth:
        return '順暢';
      case ServerLoadStatus.crowded:
        return '壅擠';
      case ServerLoadStatus.full:
        return '滿員';
      case ServerLoadStatus.maintenance:
        return '維修中';
      case ServerLoadStatus.offline:
        return '離線';
      case ServerLoadStatus.unknown:
        return '未知';
    }
  }

  bool get selectable =>
      this != ServerLoadStatus.full &&
      this != ServerLoadStatus.maintenance &&
      this != ServerLoadStatus.offline;
}

/// 單一伺服器的顯示用狀態（本地設定 + 遠端即時資料合併）。
class ServerStatus {
  const ServerStatus({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.loadStatus,
    this.online = 0,
    this.max = 0,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final ServerLoadStatus loadStatus;
  final int online;
  final int max;

  bool get selectable => loadStatus.selectable;

  factory ServerStatus.fromEntry(
    ServerEntry entry, {
    ServerLoadStatus loadStatus = ServerLoadStatus.unknown,
  }) {
    return ServerStatus(
      id: entry.id,
      name: entry.name,
      host: entry.host,
      port: entry.port,
      loadStatus: loadStatus,
    );
  }

  factory ServerStatus.fromRemote(
    Map<String, dynamic> remote,
    ServerEntry entry,
  ) {
    return ServerStatus(
      id: entry.id,
      name: entry.name,
      host: entry.host,
      port: entry.port,
      online: remote['online'] as int? ?? 0,
      max: remote['max'] as int? ?? 0,
      loadStatus: ServerLoadStatus.fromString(remote['status'] as String?),
    );
  }

  ServerStatus copyWith({ServerLoadStatus? loadStatus}) {
    return ServerStatus(
      id: id,
      name: name,
      host: host,
      port: port,
      online: online,
      max: max,
      loadStatus: loadStatus ?? this.loadStatus,
    );
  }
}
