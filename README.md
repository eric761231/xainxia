# xianxia_game

A new Flutter project.

## 專案結構 / 目錄規範

檔案依「副檔名 × 功能」歸位，放檔前請對照下表：

### 程式碼 `lib/**/*.dart`

| 功能 | 目錄 |
| --- | --- |
| UI 畫面（全螢幕 overlay） | `lib/ui/screens/` |
| UI 元件（可重用 widget） | `lib/ui/widgets/{shared,char_create,char_select}/` |
| 版面框架（XML 版面載入/spec/scale/config） | `lib/ui/layout/` |
| 樣式・字型・素材路徑常數 | `lib/ui/theme/` |
| 網路封包 | `lib/network/packets/{client,server}/`（client 只放送出、server 只放接收） |
| 封包編解碼・opcode・dispatcher | `lib/network/{codec,opcodes}/`、`lib/network/` |
| 資料模型 | `lib/models/` |
| 服務層（auth/session/world…） | `lib/services/` |
| 設定載入（app/server config） | `lib/config/` |
| 遊戲引擎（Flame）與地圖 | `lib/game/`、`lib/game/map/` |
| 通用工具 | `lib/utils/` |

### 素材 `assets/`

| 副檔名 / 功能 | 目錄 |
| --- | --- |
| `.png` 一般圖（啟動/載入背景） | `assets/images/` |
| `.png` 各畫面 UI 美術 | `assets/ui/<screen>/`（例：`char_create/`） |
| `.png` 共用 UI 美術 | `assets/ui/common/` |
| `.xml` 版面定義 | `assets/ui/layouts/` |
| `.ttf` 字型 | `assets/font/`（並於 `pubspec.yaml` `fonts:` 註冊 family） |
| `.json` 設定/遊戲資料 | `assets/data/` |
| `.json` 地圖資料 | `assets/maps/` |
| 圖磚 / 角色 sprite | `assets/tiles/`、`assets/characters/` |

> 命名一致性：`assets/ui/<screen>/` 的資料夾名與 `lib/ui/**/<screen>` 對齊（如 `char_create`）。

## Getting Started

This project is a starting point for a Flutter application.

### Server connection config

`assets/data/server_connection.json` is git-ignored because it holds an internal
host address. Before running, copy the template and set your own host:

```
cp assets/data/server_connection.example.json assets/data/server_connection.json
# then edit "host" fields (YOUR_SERVER_HOST) to point at your server
```

### 網頁連線（WebSocket）

Java 伺服器同一個埠支援原生 TCP 與 WebSocket `/ws`。網頁版自動使用
`ws://<host>:<port>/ws`；Windows／Android 等原生版本使用 TCP。
`assets/data/server_connection.json` 的 `gate` 和各 `servers` 的主機、埠仍然共用。

1. 在設定指向的主機重新編譯並啟動新版 XinServer（預設埠 `8080`）。
2. 在本專案執行：

   ```powershell
   flutter run -d chrome --web-port 3000
   ```

3. 開啟 `http://localhost:3000` 遊玩。直接開啟伺服器 `8080` 只會顯示服務說明，
   該埠不提供 Flutter 網頁素材。同機開發可將 JSON 主機設為 `127.0.0.1`；
   遠端主機必須部署新版後端並允許用戶端連入設定的埠。

若網頁使用 HTTPS，客戶端會自動使用 `wss`；設定的伺服器位址必須提供 TLS
反向代理並將 `/ws` 的 WebSocket Upgrade 轉送至 Java 伺服器。

傳輸回歸測試：

```powershell
flutter test test/network/plain_text_codec_test.dart test/network/socket_transport_io_test.dart
```

瀏覽器整合測試需先執行 Java 專案 `src/test/java` 中的 `WebSocketEchoServer`
（僅監聽 `127.0.0.1:18081`，不使用資料庫），然後執行：

```powershell
flutter test --platform chrome --dart-define=WEBSOCKET_INTEGRATION=true test/network/socket_transport_web_test.dart
```

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
