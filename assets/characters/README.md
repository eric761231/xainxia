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
- 每格尺寸 = `frameWidth` × `frameHeight`（預設 64×96），整張圖寬 = 欄數×frameWidth、
  高 = 8×frameHeight。

## descriptor 欄位（character_sprites.json）
- `defaultKey`：找不到指定 key 時使用的預設 sheet。
- `sheets.<key>.image`：本資料夾內的檔名。
- `frameWidth` / `frameHeight`：單格像素。
- `footOffsetY`：sprite 底部相對 tile 中心的上移量（微調站位）。
- `renderScale`：算繪縮放。
- `states.idle` / `states.walk`：`{ startColumn, frameCount, stepTime(秒/格) }`。

## 外觀 key 對應
目前由所選角色 `sex` 推導：`sex==1 → "female"`，否則 `"male"`
（見 `MyGame._activateWorld`）。之後可擴充依 `attribute` 等再細分。
