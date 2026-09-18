# XinProject 前端 UI XAML 外部化與素材替換接手計畫

## 1. 目標與邊界

本計畫交給下一位實作者執行，涵蓋 Loading、登入、伺服器選單、登入失敗、連線中斷、
選角、創角與遊戲 HUD。目標是讓非程式人員修改外部配置即可調整位置、尺寸、顏色、
透明度、素材路徑與顯示開關，不必進 Dart 尋找常數。

Flutter 不支援 WPF XAML。本專案所稱 XAML 是以 `package:xml` 解析的安全、自訂 XAML
子集；只描述 Flutter widget 與樣式，不允許執行程式碼。網路、狀態、Notifier、callback、
權限、導航、遊戲規則與關閉程式行為仍留在 Dart。

## 2. 已部署素材

素材已放入：

```text
XinProject/xianxia_game/assets/ui/login_flow/
  login_flow_bg.png
  loading_energy_tile.png
  icon_login_failed.png
  icon_connection_lost.png
```

| 素材 | 用途 | 注意事項 |
|---|---|---|
| `login_flow_bg.png` | Loading、登入、伺服器選單、選角、創角共用背景 | 無 UI、無文字 |
| `loading_energy_tile.png` | Loading 填充區內水平循環的透明靈氣紋理 | Flutter 負責裁切、進度與光暈 |
| `icon_login_failed.png` | 登入失敗訊息 | 建議顯示 48 至 64 logical px |
| `icon_connection_lost.png` | 連線中斷訊息 | 建議顯示 48 至 64 logical px |

不要部署 DrawPng 內的 `*_source.png`。舊 `assets/images/loading.png`、`launch_bg.png` 與
`assets/ui/common/dialog_message_bg.png` 先保留作 fallback，完成全部畫面驗收後再淘汰。

## 3. 目標 XAML 結構

```text
assets/ui/xaml/
  theme.xaml
  assets.xaml
  loading.xaml
  account.xaml
  server_select.xaml
  message_dialog.xaml
  character_select.xaml
  character_create.xaml
  game_hud.xaml
  inventory.xaml
  cultivation.xaml
  social.xaml
  decor.xaml
  gm.xaml
  portrait_anchors.xaml
```

不要同時維護兩套 XML/XAML 值。既有 `assets/ui/layouts/*.xml` 完成逐頁遷移後淘汰，遷移
期間 Dart loader 依序嘗試 `.xaml`、舊 `.xml`、Dart default。

## 4. XAML 子集

根節點固定使用 `UiView`，設計座標固定 `1920 x 1080`。建議範例：

```xml
<UiView id="account" designWidth="1920" designHeight="1080">
  <Background asset="loginFlowBg" fit="cover" alignment="center" />
  <InkFadeRect id="loginArea" centerX="960" centerY="470"
               width="620" height="620" centerOpacity="0.72"
               fadeX="120" fadeY="100" radius="0" />
  <TextField id="account" width="390" height="54" />
  <TextField id="password" width="390" height="54" />
</UiView>
```

允許節點限定為 `Background`、`Stack`、`Row`、`Column`、`Text`、`Image`、`Icon`、
`TextField`、`Button`、`ProgressBar`、`List`、`InkFadeRect`、`Spacer`、`Divider`。
未知節點或非法屬性要記錄 debug warning 並忽略，不可讓正式版崩潰。

`InkFadeRect` 必須是直角長方形：`radius=0`、不使用 `ClipRRect`、不畫邊框。它由中央
墨色向四邊透明淡出，不是圓形霧團。帳號與密碼必須引用同一個 `fieldWidth` token。

## 5. Dart 基礎設施

1. 將 `CharCreateUiDevWatcher` 泛化為 `UiXamlDevWatcher`。
2. 將 `UiLayoutXmlRegistry` 改為 `UiXamlRegistry`，登記所有 `.xaml` 與 fallback `.xml`。
3. 建立 `UiXamlLoader`、型別安全 spec 與 `XmlAttr` 共用解析；禁止 runtime reflection。
4. Debug Windows 版監看 XAML，儲存後重載目前 overlay；Release 使用 `rootBundle`。
5. 建立 `assets.xaml` 的 id-to-path manifest，Dart 不再散落硬編圖片路徑。
6. 建立 `theme.xaml` token：ink、ivory、cyan、gold、字級、陰影、spacing、fade opacity。
7. 每個數值提供 min/max clamp；解析失敗使用 Dart default，並保留目前畫面。

## 6. 素材引用替換

在 `pubspec.yaml` 新增：

```yaml
    - assets/ui/login_flow/
    - assets/ui/xaml/
```

更新 `GameUiAssets` 或改由 `assets.xaml` 管理以下 id：

```xml
<UiAssets>
  <Asset id="loginFlowBg" path="assets/ui/login_flow/login_flow_bg.png" />
  <Asset id="loadingEnergy" path="assets/ui/login_flow/loading_energy_tile.png" />
  <Asset id="loginFailedIcon" path="assets/ui/login_flow/icon_login_failed.png" />
  <Asset id="connectionLostIcon" path="assets/ui/login_flow/icon_connection_lost.png" />
</UiAssets>
```

替換引用點：

| Dart 畫面 | 現況 | 目標 |
|---|---|---|
| `loading_overlay.dart` | `assets/images/loading.png` | `loginFlowBg` + Flutter progress |
| `account.dart` | `loading.png`/`launch_bg.png` | `loginFlowBg` + `account.xaml` |
| `serverlist.dart` | Material 圓角容器 | `server_select.xaml` + 共用 InkFadeRect |
| `character_select.dart` | 舊背景與硬編位置 | `loginFlowBg` + `character_select.xaml` |
| `character_create.dart` | `loading.png`/char bg 與既有 XML | `loginFlowBg` + `character_create.xaml` |
| `transition_overlay.dart` | `loading.png` | `loginFlowBg` + `loading.xaml` |
| `game_message_dialog.dart` | `dialog_message_bg.png` + 膠囊按鈕 | `message_dialog.xaml` + 狀態 icon |

不可把 XAML 預覽圖整張當背景；文字、漸變容器、按鈕、輸入線、Loading 形狀與狀態由
Flutter 組合，PNG 只提供上表四個美術素材。

## 7. 各畫面必要規格

### Loading

- bar 無邊框，設計高度預設 `32px`，允許 `30–36px`。
- Flutter 繪製 track、fill、圓角、裁切與柔光；`loadingEnergy` 只做循環紋理。
- 進度文字由 Flutter 顯示於 bar 正中央，格式 `NN%`，不可烘進 PNG。

### 登入與伺服器選單

- 登入區使用無邊框直角墨色漸變長方形；帳號與密碼欄位等寬、左右端點對齊。
- 伺服器選單保留現有兩欄 Grid、名稱、狀態、`online/max`、更新中、取消、確認。
- 維護／離線項目維持不可點；選中效果改為淡青底線或微光，不使用填滿卡片。

### 訊息對話框

- 登入失敗現況是 `GameMessageDialog`：標題、動態原因、單一 `OK`。新版仍只有一個
  「確定」，不可自行增加重連或返回登入。
- 中斷連線現況是 `_onConnectionLost()` 後約 `300ms` 直接 `exit(0)`，沒有 UI。
- 若採用連線中斷預覽，改為顯示圖示、標題、原因、單一「關閉遊戲」；按下後才退出。
  這是明確的行為修改，需另加測試，不能只換素材。

### 選角與創角

- 共用全畫面人物舞台，不受左右 UI 欄寬影響；`centerX=960`。
- 人物比早期版縮小約 15%，腳底 anchor 對準石台中心後再上移約 `4px`。
- 創角必須顯示「選擇靈根」；四項屬性固定「神識、體魄、敏捷、悟性」。

### HUD

- 將位置、尺寸、初始開關、字級、顏色、透明度與素材 id 移入 `game_hud.xaml`。
- Notifier、網路資料、拖曳後 runtime 位置、GM 權限與 callback 留在 Dart。

## 8. 執行順序

1. 新增 XAML registry、loader、theme、assets manifest 與 fallback 測試。
2. 在 pubspec 註冊已部署素材與 XAML 目錄。
3. 先改 Loading、登入、伺服器選單；截圖確認背景切換不跳位。
4. 改共用 message dialog，再處理連線中斷退出時機。
5. 遷移選角、創角並校正人物 anchor。
6. 最後遷移 HUD 與各功能面板，避免一次改動過大。
7. 全部穩定後才移除舊 XML、`loading.png` 重複引用與 `dialog_message_bg.png`。

## 9. 驗收與測試

- 單元測試：XAML 缺檔、非法值、未知節點、color、asset id、fallback 與 clamp。
- Widget tests：`1920x1080`、`1366x768`、`1280x720`、`844x390`。
- 帳號／密碼等寬；漸變底為直角矩形且四邊淡出；所有文字不 overflow。
- Loading 0%、1%、50%、99%、100% 均正確裁切，百分比保持置中可讀。
- 維護／離線伺服器不可確認；刷新期間不重設有效選擇。
- 登入失敗關閉對話框後仍停留登入頁；中斷連線只觸發一次關閉流程。
- 選角／創角人物中心誤差 `<=4px`、腳底誤差 `<=2px`。
- Debug 修改 XAML 後可即時預覽；Release 不依賴檔案系統 watcher。

## 10. 參考預覽

- Loading：`DrawPng/out/frontend_ui_art_direction/12_borderless_loading_preview.png`
- 登入：`DrawPng/out/frontend_ui_art_direction/13_borderless_gradient_login_preview.png`
- 伺服器選單：`DrawPng/out/frontend_ui_art_direction/14_borderless_server_select_preview.png`
- 登入失敗：`DrawPng/out/frontend_ui_art_direction/16_borderless_login_failed_preview.png`
- 連線中斷：`DrawPng/out/frontend_ui_art_direction/17_borderless_connection_lost_preview.png`
- 選角：`DrawPng/out/frontend_ui_art_direction/06_borderless_fade_character_select_preview.png`
- 創角：`DrawPng/out/frontend_ui_art_direction/10_borderless_character_create_preview.png`

預覽只定義視覺與配置，不是可直接部署的整張 UI 圖。
