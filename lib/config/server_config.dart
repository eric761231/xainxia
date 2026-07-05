/// 連線設定 fallback（讀取 assets 失敗時使用）
class ServerConfig {
  ServerConfig._();

  static const int protocolVersion = 1; // 協定版本
  static const String codec = 'plain'; // 編解碼器
  static const int connectTimeoutMs = 5000; // 連接超時時間
  static const int packetTimeoutMs = 10000; // 封包超時時間
  static const String defaultServerId = 'dev_local'; // 預設伺服器 ID

  static const String fallbackHost = '10.0.2.2'; // 預設主機
  static const int fallbackPort = 8080; // 預設埠
}
