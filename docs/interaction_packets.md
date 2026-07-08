# 互動系統 C/S 封包契約

> 給後端對接用。前端已實作**送出**這些 C 封包並**接收/解析**對應 S 封包；
> 後端只要照本文件的 `op` 與 `data` 欄位實作即可。
> 傳輸格式沿用既有 JSON 信封：`{ "op": <字串>, "data": { ... } }`。

對應的互動類型定義在地圖資料的 `interactables`（見 `docs/map_pipeline.md` 與
`lib/game/map/iso_map_data.dart` 的 `MapInteractable`）。互動觸發流程一律為：
**滑鼠/手指比過去顯示指標動畫 → 點擊 → 角色走到目標相鄰一格 → 送出對應 C 封包**。

前置條件：所有 C 封包都在「角色已站到目標相鄰一格（含同格）」時才送出，
所以後端仍應**自行驗證距離**（防作弊），距離不符時回失敗。

---

## 1. 採集　C_GATHER → S_GATHER_RESULT

用於藥草、礦石等資源節點。

### C_GATHER（前端送）
```json
{ "op": "C_GATHER", "data": { "x": 5, "y": 3, "resourceId": "herb_lingzhi_01" } }
```
| 欄位 | 型別 | 說明 |
|------|------|------|
| x, y | int | 資源節點所在 tile 座標 |
| resourceId | string | 節點識別碼（地圖資料上設定） |

### S_GATHER_RESULT（後端回）
```json
{ "op": "S_GATHER_RESULT", "data": {
    "success": true, "resourceId": "herb_lingzhi_01",
    "x": 5, "y": 3, "itemId": 1001, "itemName": "千年靈芝",
    "amount": 1, "message": "", "respawnMs": 60000 } }
```
| 欄位 | 型別 | 說明 |
|------|------|------|
| success | bool | 是否成功 |
| resourceId | string | 回應的節點 |
| x, y | int | 節點座標 |
| itemId | int | 獲得道具 id（success 時） |
| itemName | string | 道具名（顯示用） |
| amount | int | 數量 |
| message | string | 失敗原因或提示（太遠／已枯竭／背包滿） |
| respawnMs | int | 此節點再生毫秒數（0＝不再生） |

---

## 2. 對話　C_INTERACT → S_DIALOG

用於 NPC、可調查物件。

### C_INTERACT（前端送）
```json
{ "op": "C_INTERACT", "data": { "npcId": 42, "x": 8, "y": 2 } }
```
| 欄位 | 型別 | 說明 |
|------|------|------|
| npcId | int | 目標 NPC／物件 id |
| x, y | int | 目標 tile 座標 |

### S_DIALOG（後端回）
```json
{ "op": "S_DIALOG", "data": {
    "npcId": 42, "npcName": "青雲門守衛",
    "text": "來者何人？此地乃青雲門重地。",
    "options": [ { "id": 1, "text": "我是新入門弟子" },
                 { "id": 2, "text": "路過而已" } ] } }
```
| 欄位 | 型別 | 說明 |
|------|------|------|
| npcId | int | 對話對象 |
| npcName | string | 顯示名 |
| text | string | 這一句對話內容 |
| options | array | 回覆分支（可空；空＝只顯示一句話）。每項 `{id:int, text:string}` |

> 註：玩家選擇 option 後的後續分支封包（例如 `C_DIALOG_CHOOSE`）尚未定義，
> 待對話系統 UI 需求明確後再補；目前前端僅顯示 text 與 options。

---

## 3. 攻擊／技能　C_USE_SKILL → S_COMBAT_RESULT

「可攻擊目標」距離滿足時，前端彈出**技能選單（純客戶端）**；
玩家選定技能後才送出 C_USE_SKILL。

### C_USE_SKILL（前端送）
```json
{ "op": "C_USE_SKILL", "data": { "skillId": 3, "targetId": 777, "x": 10, "y": 6 } }
```
| 欄位 | 型別 | 說明 |
|------|------|------|
| skillId | int | 技能 id |
| targetId | int | 目標 id |
| x, y | int | 目標 tile 座標 |

### S_COMBAT_RESULT（後端回）
```json
{ "op": "S_COMBAT_RESULT", "data": {
    "casterId": 1, "targetId": 777, "skillId": 3,
    "damage": 1580, "targetHp": 8420, "targetMaxHp": 10000,
    "killed": false, "message": "" } }
```
| 欄位 | 型別 | 說明 |
|------|------|------|
| casterId | int | 施放者 id |
| targetId | int | 目標 id |
| skillId | int | 使用的技能 |
| damage | int | 造成傷害 |
| targetHp / targetMaxHp | int | 目標剩餘／最大血量 |
| killed | bool | 是否擊殺 |
| message | string | 附加訊息（未命中／抵抗等） |

---

## 傳送門不需封包

portal（樓梯／門）類互動為**純前端本地切換地圖**，
走到相鄰一格即由客戶端載入目標地圖（`toMap/toX/toY` 在地圖資料上設定），
不經伺服器。日後若要改成伺服器主導再另定 `C_PORTAL_USE`。

---

## 前端對接位置（供除錯參考）

| 項目 | 檔案 |
|------|------|
| C 封包 build | `lib/network/packets/client/c_gather.dart`、`c_interact.dart`、`c_use_skill.dart` |
| S 封包 parse | `lib/network/packets/server/s_gather_result.dart`、`s_dialog.dart`、`s_combat_result.dart` |
| opcode 常數 | `lib/network/opcodes/client_opcodes.dart`、`server_opcodes.dart` |
| 分發 | `lib/network/packet_dispatcher.dart`（onGatherResult / onDialog / onCombatResult） |
| 送出與回應處理 | `lib/services/game_world_service.dart` |
| 互動物件資料 | `lib/game/map/iso_map_data.dart`（`MapInteractable`） |
