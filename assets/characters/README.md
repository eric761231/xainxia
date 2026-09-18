# 人物 sprite 資產規格

放置人物 sprite sheet（PNG）於本資料夾，由 [`assets/data/character_sprites.json`](../data/character_sprites.json)
描述，讀取器為 [`lib/game/map/scene_asset_loader.dart`](../../lib/game/map/scene_asset_loader.dart)
的 `SceneAssetLoader.loadCharacterSprites(key)`。**缺圖不會崩潰**，會自動回退為
canvas 火柴人（`IsoPlayerComponent` 的 fallback）。

## Sheet 版面
- 一張 sheet = 一個外觀 key（例：`male_base.png` 對應 `sheets.male`）。
- **每一列（row）= 一個面向 facing**，共 8 列，row index 即 facing 值：

  | row | facing | 方向 |
  |-----|--------|------|
  | 0 | 0 | NE 右上 |
  | 1 | 1 | E 右 |
  | 2 | 2 | SE 右下 |
  | 3 | 3 | S 下 |
  | 4 | 4 | SW 左下 |
  | 5 | 5 | W 左 |
  | 6 | 6 | NW 左上 |
  | 7 | 7 | N 上 |

- **每一欄（column）= 一個影格**。同一列中，`idle` 與 `walk` 各占一段連續欄位，
  由 descriptor 的 `startColumn` / `frameCount` 指定（預設 idle=col0–3、walk=col4–9）。
- 每格尺寸 = `frameWidth` × `frameHeight`（目前 64×128），整張圖寬 = 欄數×frameWidth、
  高 = 8×frameHeight。

## descriptor 欄位（character_sprites.json）
- `defaultKey`：找不到指定 key 時使用的預設 sheet。
- `sheets.<key>.image`：本資料夾內的檔名。
- `frameWidth` / `frameHeight`：單格像素。
- `footOffsetY`：sprite 底部相對 tile 中心的上移量（微調站位）。
- `renderScale`：算繪縮放。
- `states.idle` / `states.walk`：`{ startColumn, frameCount, stepTime(秒/格) }`。

## 3221 圖集與動畫對接規格（`3221.png` + `3221.json`）
- 本資料夾提供 `3221.png` 與逐幀 rect + offset 的 `3221.json`。
- `facing_map` 將遊戲方向映射到素材方向。3221 素材的方向順序從 NW 開始，
  因此使用 `[2,3,4,5,6,7,0,1]` 對齊遊戲的 NE、E、SE、S、SW、W、NW、N。
- 動畫編號與動作對應：
  - `3221-0` ~ `3221-7`：**行走（walk）**（素材方向 0..7）
  - `3221-8` ~ `3221-15`：**站立休息（idle）**（素材方向 0..7）
  - `3221-16` ~ `3221-23`：**攻擊（attack）**（素材方向 0..7）
  - `3221-24` ~ `3221-31`：**受傷（hurt）**（素材方向 0..7）
  - `3221-96` ~ `3221-103`：**死亡（death）**（素材方向 0..7）
- 由 [`lib/game/map/l1_sprite_sheet.dart`](../../lib/game/map/l1_sprite_sheet.dart) 自動解析對接至遊戲內的動作狀態，並由 [`lib/game/map/iso_player_component.dart`](../../lib/game/map/iso_player_component.dart) 播放。

## 外觀 key 對應
目前由所選角色 `sex` 推導：`sex==1 → "female"`，否則 `"male"`
（見 `MyGame._activateWorld` 與 `assets/data/character_sprites.json`）。兩者皆配置讀取 `assets/characters/3221.png`。

## Mixamo 轉圖流程（`tools/sprites/`）
把 Mixamo 的 3D 角色在 Blender 裡渲染成 8 方向，打包成與 `mountain_wolf.json` 相同的 L1 圖集
（`<動作>-<facing>` + 逐幀 rect/offset），`L1SpriteSheet` 直接可讀，不用改程式。

1. **下載 FBX**（Mixamo，每個動作一個檔）：Format **FBX Binary**、Skin **With Skin**、30 fps、
   Keyframe Reduction none；走路要勾 **In Place**。存到 repo 外面（Mixamo 授權不允許散佈原始檔）：
   ```
   ../art_source/mixamo/<key>/idle.fbx walk.fbx attack.fbx hurt.fbx death.fbx
   ```
2. **執行**（repo 根目錄，需要 Blender 5.x 與 Python + Pillow）：
   ```
   python tools/sprites/mixamo_to_l1.py --job brady    # 省略 --job 就跑全部
   ```
   FBX 沒變就沿用 `build/mixamo_sprites/` 裡的渲染結果；`--force` 強制重渲染。
3. **檢查** `build/mixamo_sprites/preview_<key>.png`：S 面向鏡頭、E 朝畫面右方、紅十字落在腳底。
4. **測試** `flutter test test/game/mixamo_sheets_test.dart`。

- 新增角色：在 `tools/sprites/mixamo_sprites.json` 的 `jobs` 加一筆（`key`、`src`、`out`），
  大隻的怪可覆寫 `canvas`（畫布邊長）與 `targetZ`（攝影機瞄準高度）。
- 尺寸：`pxPerMeter` 115 讓 1.8m 的人約 180px 高，圖是顯示尺寸，`renderScale` 用 1.0。
- 主角：改 `character_sprites.json` 的 `sheets.<key>.l1`；怪物：加進
  `IsoMonsterComponent._sheetByName`（以伺服器上的怪物名稱對應）。
