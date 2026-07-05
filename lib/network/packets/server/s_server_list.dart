/// 伺服器列表回應（各區即時狀態）。
class SServerList {
  const SServerList({required this.servers});

  final List<Map<String, dynamic>> servers;

  factory SServerList.fromData(Map<String, dynamic> data) {
    final raw = data['servers'] as List<dynamic>? ?? [];
    return SServerList(
      servers: raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}
