# assets/objects/ — 布置物件（prop）美術

把要擺進地圖的物件圖片放在這裡（樹、房屋、花草等），並在
`assets/data/object_catalog.json` 為每張圖登記一筆物件定義。

> 單張圖的「場景背景」不放這裡，放 `assets/sences/`（見地圖 JSON 的 `background`）。

## 一檔一物件（預設，最簡單）
每張 PNG 一個物件，catalog 只需最小欄位：
```json
"1010": { "image": "tree001.png", "blocking": true, "label": "樹一" }
```
- 省略 `src` → 用**整張圖**。
- 省略 `anchor` → 腳底錨點取**底邊中央**（物件底部站在格中心）。
- `blocking:true` → 依 `footprint`（預設 1×1）把佔用格設為不可走。
- 深度：遊戲內依腳底 y 與玩家一起排序 → 玩家可走到物件前方或後方
  （花在門前、樹在屋後自動正確）。同腳底 y 想微調前後，於地圖物件加 `zBias`。

## 用 sences / tiles 的圖當物件
物件圖不限放本資料夾。catalog 條目加 `"dir"` 即可指定來源資料夾：
- `"dir":"objects"`（預設）→ `assets/objects/`
- `"dir":"sences"` → `assets/sences/`（場景圖當物件）
- `"dir":"tiles"` → `assets/tiles/`（地形圖當物件）

id 分區慣例：objects `1000+`、sences `2000+`、tiles `3000+`（避免地圖存檔的 id 參照飄移）。
新增檔案要能在物件欄選取，需自己在 catalog 補一筆對應條目。

## SVG 向量圖
catalog 條目的 `image` 直接指向 `.svg` 檔即可（可放在 objects/sences/tiles 任一資料夾）。
SVG 走**向量渲染**（縮放不失真），其餘（palette、深度、尺寸、offset、ghost）與點陣圖一致。
由 flutter_svg 解析；`ObjectGraphic`（`lib/game/map/iso_object_graphic.dart`）統一點陣/向量兩種來源。

## 尺寸調整（編輯器）
放置後選取物件，右側可用 `+/-` 調整寬度格數（等比縮放，寬 = N 格 × 64px、高依長寬比），
存為該物件的 `tilesW`（0＝原尺寸）。碰撞 footprint 仍由 catalog 定，不隨視覺尺寸變動。

## atlas 打包（多物件一張圖）
需要時可用 `src`/`anchor` 明確裁切（見 docs/map_pipeline.md §4）：
```json
"2001": { "image": "props.png", "src": [0,0,128,192], "anchor": [64,180],
          "footprint": [1,1], "blocking": true }
```

## 目前檔案與目錄（object_catalog.json 已登記）
- 花（不擋）：`flowers001.png`(1001)、`flower002..005.png`(1002–1005)
- 樹（擋）：`tree001.png`(1010)、`tree002.png`(1011)
- 房（擋，footprint 2×2）：`house025.png`(1020)、`house034.png`(1021)、
  `house036.png`(1022)、`house26.png`(1023)

房屋的 `footprint` 預設 2×2，可依實際圖大小在 catalog 調整。
