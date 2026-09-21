-- 修練洞府（map 0）房間擺設。由 DrawPng/build_map0_furnishing_sql.py 產生，請勿手改；
-- 要調整請改 out/cave_furnishings/map0_layout.json 或 object_catalog.json 後重跑。
--
-- 一、地圖：範圍 31..40（10x10 格，112x56），layout_mode=static
-- 二、家具模板：footprint 與 blocking 與前端 catalog 逐項相同
--     （碰撞在伺服器、接地陰影在前端，不一致就會「看得到卻走得過去」）
-- 三、生成點：先清掉地圖 0 所有場景物件生成點，再照 layout 插入 8 件
--
-- 可重複執行。只動地圖 0 的地圖設定與場景物件，不碰角色、NPC、怪物與其他地圖。
-- 角色自己布置的家具在 character_decoration，不受影響。
-- 套用後重啟伺服器（生成點只在啟動時讀一次）。

START TRANSACTION;

-- 一、地圖
UPDATE `map` SET `layout_mode` = 'static', `min_x` = 31, `max_x` = 40, `min_y` = 31, `max_y` = 40
WHERE `map_id` = 0;

-- 二、家具模板（id 與 pngid 同號）
INSERT INTO `property`
  (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`,
   `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`)
VALUES
  (4101,4101,1,1,3,0,0,'floor','洞府書櫃（左牆）',0,0,0,''),
  (4102,4102,1,1,1,0,0,'floor','白蘭花盆',0,0,0,''),
  (4103,4103,1,1,1,0,0,'floor','松樹盆景',0,0,0,''),
  (4104,4104,1,3,1,0,0,'floor','紅楓長盆',0,0,0,''),
  (4105,4105,1,2,1,0,0,'floor','靈石竹簡櫃',0,0,0,''),
  (4106,4106,1,1,1,0,0,'floor','直立綠植',0,0,0,''),
  (4107,4107,0,1,1,0,0,'floor','聚靈法陣',0,0,0,'')
ON DUPLICATE KEY UPDATE
  `pngid`       = VALUES(`pngid`),
  `blocking`    = VALUES(`blocking`),
  `footprint_w` = VALUES(`footprint_w`),
  `footprint_h` = VALUES(`footprint_h`),
  `placeable`   = VALUES(`placeable`),
  `placement`   = VALUES(`placement`),
  `view_note`   = VALUES(`view_note`);

-- 三、生成點（range=0 代表座標固定）
DELETE FROM `spawnlist_scene` WHERE `mapid` = 0;
INSERT INTO `spawnlist_scene`
  (`zone`, `property_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`)
VALUES
  ('修練洞府',4103,'松樹盆景',1,31,31,0,0),
  ('修練洞府',4104,'紅楓長盆',1,34,31,0,0),
  ('修練洞府',4105,'靈石竹簡櫃',1,39,31,0,0),
  ('修練洞府',4106,'直立綠植',1,40,31,0,0),
  ('修練洞府',4101,'洞府書櫃（內）',1,31,34,0,0),
  ('修練洞府',4101,'洞府書櫃（外）',1,31,39,0,0),
  ('修練洞府',4102,'白蘭花盆',1,31,40,0,0),
  ('修練洞府',4107,'聚靈法陣',1,35,35,0,0);

COMMIT;
