-- ============================================================================
--  既有資料庫升級：spawnlist 拆成三張表
-- ----------------------------------------------------------------------------
--  spawnlist_scene   場景物件（原 obj_type = 'property'）
--  spawnlist_npc     NPC（原 obj_type = 'npc'，且模板不是怪物）
--  spawnlist_monster 怪物（原 obj_type = 'monster'，或模板 npc.type_name = 'monster'）
--
--  ・可重複執行：每次先清空三張新表再從舊 spawnlist 複製。
--  ・舊的 spawnlist 不會刪除；確認伺服器載入正常後，再手動執行最下方的 DROP。
--  ・舊表不一定有 respawn_delay 欄位，怪物一律先給 15 秒，之後逐筆調整。
--  ・執行完需重啟伺服器。
-- ============================================================================

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `spawnlist_scene` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '資料序號',
  `zone` varchar(255) DEFAULT NULL COMMENT '地區註解',
  `property_id` int(10) NOT NULL COMMENT '場景物件模板（property.id）',
  `name` varchar(255) DEFAULT NULL COMMENT '名稱註解',
  `count` int(10) NOT NULL DEFAULT '1' COMMENT '數量',
  `locx` int(10) NOT NULL COMMENT '中心X座標',
  `locy` int(10) NOT NULL COMMENT '中心Y座標',
  `range` int(10) NOT NULL DEFAULT '0' COMMENT '散佈範圍（0=固定座標）',
  `mapid` int(10) NOT NULL DEFAULT '0' COMMENT '地圖編號',
  PRIMARY KEY (`id`),
  KEY `idx_mapid` (`mapid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='場景物件生成點';

CREATE TABLE IF NOT EXISTS `spawnlist_npc` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '資料序號',
  `zone` varchar(255) DEFAULT NULL COMMENT '地區註解',
  `npc_id` int(10) NOT NULL COMMENT 'NPC模板（npc.npc_id）',
  `name` varchar(255) DEFAULT NULL COMMENT '名稱註解',
  `count` int(10) NOT NULL DEFAULT '1' COMMENT '數量',
  `locx` int(10) NOT NULL COMMENT '中心X座標',
  `locy` int(10) NOT NULL COMMENT '中心Y座標',
  `range` int(10) NOT NULL DEFAULT '0' COMMENT '散佈範圍（0=固定座標）',
  `mapid` int(10) NOT NULL DEFAULT '0' COMMENT '地圖編號',
  PRIMARY KEY (`id`),
  KEY `idx_mapid` (`mapid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='NPC生成點';

CREATE TABLE IF NOT EXISTS `spawnlist_monster` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '資料序號',
  `zone` varchar(255) DEFAULT NULL COMMENT '地區註解',
  `npc_id` int(10) NOT NULL COMMENT '怪物模板（npc.npc_id）',
  `name` varchar(255) DEFAULT NULL COMMENT '名稱註解',
  `count` int(10) NOT NULL DEFAULT '1' COMMENT '數量',
  `locx` int(10) NOT NULL COMMENT '中心X座標',
  `locy` int(10) NOT NULL COMMENT '中心Y座標',
  `range` int(10) NOT NULL DEFAULT '5' COMMENT '散佈範圍',
  `mapid` int(10) NOT NULL DEFAULT '0' COMMENT '地圖編號',
  `respawn_delay` int(10) NOT NULL DEFAULT '15' COMMENT '重生延遲（秒），0=不重生',
  PRIMARY KEY (`id`),
  KEY `idx_mapid` (`mapid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='怪物生成點';

DELETE FROM `spawnlist_scene`;
DELETE FROM `spawnlist_npc`;
DELETE FROM `spawnlist_monster`;

INSERT INTO `spawnlist_scene` (`zone`, `property_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`)
SELECT s.`zone`, s.`npc_id`, s.`name`, s.`count`, s.`locx`, s.`locy`, s.`range`, s.`mapid`
FROM `spawnlist` s
WHERE s.`obj_type` = 'property'
ORDER BY s.`id`;

INSERT INTO `spawnlist_monster` (`zone`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`, `respawn_delay`)
SELECT s.`zone`, s.`npc_id`, s.`name`, s.`count`, s.`locx`, s.`locy`, s.`range`, s.`mapid`, 15
FROM `spawnlist` s
WHERE s.`obj_type` <> 'property'
  AND (s.`obj_type` = 'monster'
       OR EXISTS (SELECT 1 FROM `npc` n WHERE n.`npc_id` = s.`npc_id` AND n.`type_name` = 'monster'))
ORDER BY s.`id`;

INSERT INTO `spawnlist_npc` (`zone`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`)
SELECT s.`zone`, s.`npc_id`, s.`name`, s.`count`, s.`locx`, s.`locy`, s.`range`, s.`mapid`
FROM `spawnlist` s
WHERE s.`obj_type` <> 'property'
  AND s.`obj_type` <> 'monster'
  AND NOT EXISTS (SELECT 1 FROM `npc` n WHERE n.`npc_id` = s.`npc_id` AND n.`type_name` = 'monster')
ORDER BY s.`id`;

-- 核對筆數：三張新表加總應等於舊表
SELECT
  (SELECT COUNT(*) FROM `spawnlist`)         AS old_total,
  (SELECT COUNT(*) FROM `spawnlist_scene`)   AS scene_rows,
  (SELECT COUNT(*) FROM `spawnlist_npc`)     AS npc_rows,
  (SELECT COUNT(*) FROM `spawnlist_monster`) AS monster_rows;

-- 確認伺服器啟動記錄出現「載入場景物件生成點 / NPC 生成點 / 怪物生成點」且數量正確後，再執行：
-- DROP TABLE `spawnlist`;
