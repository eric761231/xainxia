# 地圖 tile 圖集規格

放置等距地圖 tile 圖集（sprite sheet PNG）於本資料夾，由地圖 JSON
（`assets/maps/<mapId>.json`）的 `tilesets[]` 描述，讀取器為
[`lib/game/map/scene_asset_loader.dart`](../../lib/game/map/scene_asset_loader.dart)
的 `SceneAssetLoader.loadTileAtlas(image)`。**缺圖不會崩潰**，會自動回退為
色塊菱形（`IsoMapComponent` 的 `_drawFallbackTile`）。

## 地圖 JSON 的 tilesets 欄位
`assets/maps/<mapId>.json`：
```json
{
  "tileWidth": 64,
  "tileHeight": 32,
  "tilesets": [
    { "firstId": 1, "image": "ground.png", "tileWidth": 64, "tileHeight": 32, "columns": 8 }
  ],
  "layers": [ { "name": "ground", "data": [[ ... tileId ... ]] } ]
}
```
- `firstId`：此圖集第一格對應的 tileId（layer.data 內的值）。多圖集時，
  依 `firstId <= tileId` 取最後符合者（見 `IsoMapComponent._findTileset`）。
- `image`：本資料夾內的檔名（前綴 `assets/tiles/`）。
- `tileWidth` / `tileHeight`：單格像素（等距菱形建議 64×32）。
- `columns`：圖集每列格數，用來由 `localId` 換算 col/row。

`layers[].data[y][x]` = tileId；`0` 表示空格不繪製。

## 目前狀態
`0.json` 的 `tilesets` 為空 → 全部走色塊 fallback。放好圖集並在 map JSON
填入 `tilesets` 後即改用圖集算繪。
