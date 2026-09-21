# 地圖圖磚資料

每張地圖一個 `<mapId>.json`，描述**哪個座標用哪一張圖磚**。
由 `MapTileTable` 在首次用到時載入並常駐快取，經 `S_MAP_TILES` 送給前端。

## 為什麼放在伺服器

在此之前這份資料是前端資產（`assets/maps/0.json`），而地圖邊界同時存在
DB 的 `map.min_x/max_x` 與那份 JSON 裡 —— 兩份會漂移。DB 改了邊界前端不會
跟著變，座標空間就錯開，而且不會拋例外，只表現成「人物站的位置怪怪的」。

現在資料只有伺服器這一份，前端只保留圖檔。

## 統一的圖磚代號（tileId）

前後端溝通一律用 **tileId**，不是「圖集裡的第幾格」。

    tileId = tilesets[].firstId + 圖集內索引

前端拿 tileId 去 `IsoTileset.srcRectForId()` 換算來源矩形，**不需要知道
圖集怎麼排**。重產圖集只要改這裡的 `columns`／`firstId`，地圖資料不用動。

號段（新增類別時往下接，不要與既有重疊）：

| 號段 | 用途 |
|---|---|
| 0 | 保留：不繪製 |
| 1001–1999 | 地面 |
| 2001–2999 | 牆面 |
| 3001–3999 | 裝飾覆蓋層 |

## 欄位

```jsonc
{
  "mapId": 0,
  "tileWidth": 64, "tileHeight": 32,
  "coordOffset": 30,          // 陣列索引 0 對應的地圖格座標
  "walkMin": 31, "walkMax": 50,
  "tilesets": [
    { "firstId": 1001, "image": "ground_brick.png",
      "tileWidth": 64, "tileHeight": 32, "columns": 8 }
  ],
  "ground": [[0,0,...], ...]  // 逐格 tileId，0 = 不繪製
}
```

`coordOffset`／`walkMin`／`walkMax` **必須與 DB 的 `map` 表一致** ——
`MapTileTable` 載入時會核對，不一致會在啟動記錄警告。
