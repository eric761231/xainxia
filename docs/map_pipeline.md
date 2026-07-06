# 地圖資產管線規範（Map Pipeline Spec）

本文件是「切圖」與「拼圖」共同遵守的規則書。切圖時照此輸出、拼圖（編輯器）與載入器照此讀寫。

---

## 1. 座標與尺寸

- 等距投影，比例 **2:1**。
- 地形 tile 基準尺寸：**寬 64 × 高 32**（`tileWidth=64`, `tileHeight=32`）。
- 投影公式（見 [`lib/game/map/iso_coord.dart`](../lib/game/map/iso_coord.dart)）：
  - `tileToScreen(tx,ty) = ((tx-ty)*halfW, (tx+ty)*halfH)`，`halfW=32, halfH=16`，回傳菱形**頂點**。
  - `screenToTile(pos)`：以 floor 對應到唯一格子。
- 螢幕座標原點：tile (0,0) 的頂點；渲染 anchor = topLeft。

## 2. 目錄結構

| 內容 | 位置 | 狀態 |
|------|------|------|
| 地形 tile atlas | `assets/tiles/` | 使用中 |
| 物件 atlas | `assets/objects/` | 第二版預留 |
| 物件目錄 metadata | `assets/data/object_catalog.json` | 第二版預留 |
| 地圖檔 | `assets/maps/{id}.json` | 使用中 |

> **atlas 共用、地圖檔只存佈局**：所有地圖共用同一批 atlas，`{id}.json` 只記「哪一格放哪個 id」，不逐圖複製美術。

## 3. 地形 Atlas 規格

- 每格精確 **64×32**、透明背景、菱形頂面對齊格線、相鄰可無縫拼接。
- 一張 atlas 為橫向/格狀排列的 sprite sheet；於地圖檔的 `tilesets` 宣告：
  - `firstId`：此 atlas 第一格對應的 tileId。
  - `image`：檔名（相對 `assets/tiles/`）。
  - `tileWidth` / `tileHeight`：每格像素（通常 64/32）。
  - `columns`：每列格數；`localId = tileId - firstId`，`col = localId % columns`，`row = localId ~/ columns`。
- **概念圖 ≠ 可用圖塊**：展示用概念稿需重新以格線尺寸、透明背景、正確拼接輸出，勿直接切 JPG。

## 4. 物件 metadata（第二版預留）

物件（樹/建築/家具/設施）不是地板 tile，另存於 `assets/objects/` + `object_catalog.json`：

```jsonc
{
  "objects": {
    "1001": {
      "image": "trees.png",       // 相對 assets/objects/
      "src": [0, 0, 128, 192],    // atlas 內裁切 [x,y,w,h]
      "anchor": [64, 180],        // 腳底錨點(px)，對齊所在格中心
      "footprint": [1, 1],        // 佔幾格 (w,h)
      "blocking": true            // 是否阻擋行走
    }
  }
}
```

- **錨點(anchor)**：物件「站」在格子上的接地點（通常底部中央），渲染時對齊該格中心。
- **footprint**：佔用的格數，用於碰撞/放置合法性。
- **深度排序**：物件依腳底 y（`tx+ty` 或世界 y）排序繪製，讓角色能走到物件後方（與 `IsoPlayerComponent` 的 `footOffsetY` 同一套機制）。

## 5. 地圖檔 `{id}.json` 格式

```jsonc
{
  "id": "0",
  "name": "新手村",
  "width": 16, "height": 16,
  "tileWidth": 64, "tileHeight": 32,
  "tilesets": [
    { "firstId": 1, "image": "ground.png", "tileWidth": 64, "tileHeight": 32, "columns": 8 }
  ],
  "layers": [
    { "type": "tiles", "name": "ground", "data": [[4,4,...],[4,1,...]] },
    { "type": "objects", "name": "props", "objects": [ { "id": 1001, "x": 3, "y": 5 } ] }
  ]
}
```

- **tile 層**：`data[row][col] = tileId`，`0` = 空。目前 `layers` 未帶 `type` 者一律視為 `tiles`（向後相容現有 `assets/maps/0.json`）。
- **物件層**（第二版）：`objects: [{id,x,y}]`，`id` 對應 `object_catalog.json`。
- 缺 atlas 時 tileId 1~8 有內建色塊 fallback（見 [`iso_tile_palette.dart`](../lib/game/map/iso_tile_palette.dart)），故**無美術也能拼版**。

## 6. id 編號慣例

| 範圍 | 用途 |
|------|------|
| `0` | 空格（tile 層）／未使用 |
| `1 – 999` | 地形 tileId |
| `1000+` | 物件 objectId（物件目錄鍵） |

分段可讓載入器/編輯器一眼分辨 tile 與物件，避免衝突。

---

## 附：工作流程

1. **切圖**：概念稿 → 影像編輯器（Krita/Photoshop）切成成品 → 打包 atlas（TexturePacker/Free Texture Packer）；規則網格可用 ImageMagick 批次切。
2. **拼圖**：自製編輯器（`lib/tools/map_editor_main.dart`）塗地形/擺物件 → 存回 `assets/maps/{id}.json`。
3. **載入**：`IsoMapLoader.load(id)` → `IsoMapComponent` 渲染。
