# 素材 Alpha 檢查與立繪發布

從專案根目錄執行，需要 Flutter/Dart、Node.js 與已安裝的 pub dependencies。

```powershell
dart run tools/assets/audit_alpha.dart
dart run tools/assets/contact_sheets.dart
node tools/assets/audit_render_opacity.cjs
node tools/assets/audit_references.cjs
```

前三個盤點工具只讀素材，報告寫入 `docs/` 和 `docs/alpha/`。`audit_alpha.dart` 遍歷專案圖片，跳過隱藏工具目錄、build、node_modules 與自身輸出。引用搜尋是候選清單，動態地圖來源和未測情境另有分類；有字串引用不代表已在遊戲中實際顯示。所有圖集 JSON 的 rect 都逐幀掃描；無描述檔的歷史素材不猜測影格尺寸。

本次立繪修復可由留存輸入重現：

```powershell
dart run tools/assets/repair_portrait_alpha.dart
node tools/assets/publish_portraits.cjs
node tools/assets/publish_portraits.cjs --check
```

**修復命令會覆寫目前的男女立繪來源。** 它是本次兩張特定圖片的修復配方，不是通用去背工具；不可套用到尺寸、人物或構圖不同的新圖。原始輸入在 `docs/alpha/before/`，女性頭髮重建參考在 `docs/alpha/hair_reconstruction_reference.png`。人物外緣、薄紗、服裝和膚色不做全圖 Alpha 門檻處理。

發布工具從來源內容計算 SHA-256，產生含雜湊的 PNG、更新 Dart 路徑常數與 `published_assets.json`。保留既有版本檔，不自動刪除歷史資源。`--check` 不修改檔案，來源／發布檔／常數不一致時會失敗。

```powershell
flutter test test/ui/asset_alpha_test.dart test/ui/portrait_render_test.dart test/ui/login_flow_test.dart test/ui/account_server_select_test.dart test/game/object_opacity_test.dart test/game/monster_corpse_test.dart
flutter build web --no-wasm-dry-run
node tools/preview/serve.cjs build/web 3000
```

素材測試輸出 Flutter bundle 解碼清單；畫面測試輸出三種尺寸的創角／選角 PNG。測試後再跑盤點可將 bundle 結果帶入 CSV。這些測試不連線、不建立或刪除伺服器角色。

Web 離線驗收使用正式畫面元件和測試角色資料：

```powershell
flutter build web --no-wasm-dry-run --target tools/preview/alpha_preview.dart --output build/alpha_preview
node tools/preview/serve.cjs build/alpha_preview 3001
```

3001 是離線視覺驗收，3000 是正式入口；兩者不可混當成已完成伺服器登入驗證。預覽服務只綁定 127.0.0.1，並回傳 no-store。
