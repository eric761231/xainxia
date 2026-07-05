# UI 資源目錄

## 分工

| 類型 | 目錄 | Dart 入口 | 用途 |
|------|------|-----------|------|
| PNG 切圖 | `assets/ui/{screen}/` | `lib/.../{screen}_ui_assets.dart` | 路徑常數 |
| 布局 XML | `assets/ui/{screen}/{screen}_layout.xml` | `{screen}_ui_loader.dart` → `{screen}_ui_spec.dart` | 尺寸、位置、色票 |
| 共用切圖 | `assets/ui/common/` | `GameUiAssets` | 跨畫面 dialog 等 |

**PNG 路徑不寫入 XML**；換圖改 PNG 檔 + `*_ui_assets.dart`（並同步 `allPreloadPaths`）。

## 目錄

```text
assets/ui/
├── common/           # 共用（dialog_message_bg 等）
├── create_char/      # 創角切圖 + char_create_layout.xml
├── character_select/ # 選角（待建）
└── natal_weapons/    # 保留
```

## 預載時機

| 階段 | 內容 |
|------|------|
| App 啟動 | `loading.png`、`server_connection.json` |
| **登入成功過場** | `CharCreateUiPreloader`：XML + 創角全部 PNG + common dialog bg |
| 進入創角 | 正常流程無空白等待（已預載） |

修改 `char_create_layout.xml` 後：

| 執行環境 | 預覽方式 |
|----------|----------|
| **Debug + 桌面**（`flutter run -d windows` 等，工作目錄為專案根） | 存檔 XML 後約 0.25s 自動刷新；創角頁右上角顯示 **XML Live · scale** |
| Debug + 手機 / Release | 需 **Hot Restart**（讀取打包 assets） |

## 跨平台尺寸一致化

- 基準稿：**1920×1080**（`<charCreate designWidth designHeight>`）
- 縮放：`scale = min(可用寬/1920, 可用高/1080)`，限制在 `scaleMin`～`scaleMax`
- 固定 px（寬高、字級、padding）會乘 `scale`；`*Fraction` 比例類不縮放
- 桌面 Debug 建議視窗 **16:9（如 1920×1080）** 可得到 scale≈1，與主流手機橫屏最接近

新增其他畫面的布局 XML 時，請在 [`ui_layout_xml_registry.dart`](../../lib/auth_login/ui_layout_xml_registry.dart) 的 `UiLayoutXmlRegistry.all` 登記 path，即可共用即時預覽。

## 創角 PNG ↔ Dart 常數

| 檔名 | `CharCreateUiAssets` |
|------|----------------------|
| `char_bg.png` | `bg` |
| `panel_left.png` | `panelLeft` |
| `attr_metal.png` … `attr_illusion.png` | `attrMetal` … `attrIllusion` |
| `char_male/female.png` | `charMale` / `charFemale` |
| `input_cotact.png` | `inputContact` |
| `option.png` | `option`（屬性列底圖） |
| `btn01.png` / `btn01_selected.png` | `btn01` / `btn01Selected`（性別、靈根列：未選/選中切圖，無 overlay 金框） |
| `start_btn.png` / `start_btn_hover.png` / `start_btn_pressed.png` | `startBtn` / `startBtnHover` / `startBtnPressed` |
| `back_icon.png` / `back_icon_hover.png` / `back_icon_pressed.png` | `backIcon` / `backIconHover` / `backIconPressed` |
| `spirit_icon.png` 等 | `spiritIcon` 等 |
| `reduce_btn.png` / `add_btn.png` | `reduceBtn` / `addBtn` |

布局數值見 `char_create_layout.xml` → `CharCreateUiSpec`。
