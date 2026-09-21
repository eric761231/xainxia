-- ============================================================================
--  NPC AI 升級（階段 0 修正、階段 1 生成系統、階段 2 AI 核心）
-- ----------------------------------------------------------------------------
--  npc 表補上 hit（命中）與 dodge（閃避）。
--
--  程式（NpcTable）一直在讀這兩欄，但 schema_all.sql 的建表沒有它們 ——
--  用乾淨 schema 建的資料庫會讓整個 npc 表載入失敗、地圖上一隻怪都沒有。
--  （伺服器現在已改成缺欄位時警告並以 0 代入，但資料庫仍應補齊。）
--
--  ・可重複執行：欄位已存在就跳過。
--  ・執行完需重啟伺服器。
--  ・之後的階段（生成、AI 參數）會繼續追加到這個檔案。
-- ============================================================================

SET NAMES utf8mb4;

SET @ddl := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'hit') = 0,
  'ALTER TABLE `npc` ADD COLUMN `hit` int(10) NOT NULL DEFAULT 0 COMMENT ''命中'' AFTER `rand_damage`',
  'SELECT ''npc.hit 已存在，略過'' AS info');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @ddl := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'dodge') = 0,
  'ALTER TABLE `npc` ADD COLUMN `dodge` int(10) NOT NULL DEFAULT 0 COMMENT ''閃避'' AFTER `hit`',
  'SELECT ''npc.dodge 已存在，略過'' AS info');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 核對
SELECT COLUMN_NAME, COLUMN_TYPE, COLUMN_DEFAULT
  FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME IN ('hit', 'dodge');

-- ============================================================================
--  階段 1：生成系統
-- ----------------------------------------------------------------------------
--  spawnlist_monster：重生隨機延遲、牽引距離、初始面向、生成類型
--  spawnlist_npc    ：初始面向
--  （同樣可重複執行；欄位已存在就跳過。伺服器在欄位不存在時會用預設值並警告。）
-- ============================================================================

SET @ddl := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'spawnlist_monster' AND COLUMN_NAME = 'respawn_delay_random') = 0,
  'ALTER TABLE `spawnlist_monster` ADD COLUMN `respawn_delay_random` int(10) NOT NULL DEFAULT 0 COMMENT ''重生延遲隨機加值（秒）：實際 = respawn_delay + rand(0..此值)'' AFTER `respawn_delay`',
  'SELECT ''spawnlist_monster.respawn_delay_random 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'spawnlist_monster' AND COLUMN_NAME = 'movement_distance') = 0,
  'ALTER TABLE `spawnlist_monster` ADD COLUMN `movement_distance` int(10) NOT NULL DEFAULT 12 COMMENT ''離家最大距離（格），超過就脫戰回家；0=不限制'' AFTER `respawn_delay_random`',
  'SELECT ''spawnlist_monster.movement_distance 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'spawnlist_monster' AND COLUMN_NAME = 'heading') = 0,
  'ALTER TABLE `spawnlist_monster` ADD COLUMN `heading` int(10) NOT NULL DEFAULT 2 COMMENT ''初始面向 0..7；-1=隨機'' AFTER `movement_distance`',
  'SELECT ''spawnlist_monster.heading 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'spawnlist_monster' AND COLUMN_NAME = 'spawn_type') = 0,
  'ALTER TABLE `spawnlist_monster` ADD COLUMN `spawn_type` tinyint(4) NOT NULL DEFAULT 0 COMMENT ''0=一般 1=首領（固定座標不散佈）'' AFTER `heading`',
  'SELECT ''spawnlist_monster.spawn_type 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'spawnlist_npc' AND COLUMN_NAME = 'heading') = 0,
  'ALTER TABLE `spawnlist_npc` ADD COLUMN `heading` int(10) NOT NULL DEFAULT 2 COMMENT ''初始面向 0..7；-1=隨機'' AFTER `mapid`',
  'SELECT ''spawnlist_npc.heading 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 核對
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_DEFAULT
  FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE()
   AND ((TABLE_NAME = 'spawnlist_monster' AND COLUMN_NAME IN ('respawn_delay_random','movement_distance','heading','spawn_type'))
     OR (TABLE_NAME = 'spawnlist_npc' AND COLUMN_NAME = 'heading'));

-- ============================================================================
--  階段 2：AI 核心
-- ----------------------------------------------------------------------------
--  npc：移動／攻擊速度、主動攻擊、察覺範圍、遊走、攻擊距離、NPC 閒聊
--  spawnlist_monster：安全區（如地圖 0 修練洞府）不再生怪，把原本在安全區的怪物生成點
--                     搬到黑森林（地圖 1）中央的開闊區域。
--  （同樣可重複執行。）
-- ============================================================================

SET @ddl := IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'passispeed') = 0,
  'ALTER TABLE `npc` ADD COLUMN `passispeed` int(10) NOT NULL DEFAULT 800 COMMENT ''走一格的毫秒數；前端插值約 400ms，不可低於 400''',
  'SELECT ''npc.passispeed 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'atkspeed') = 0,
  'ALTER TABLE `npc` ADD COLUMN `atkspeed` int(10) NOT NULL DEFAULT 1200 COMMENT ''攻擊一次的毫秒數''',
  'SELECT ''npc.atkspeed 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'agro') = 0,
  'ALTER TABLE `npc` ADD COLUMN `agro` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''是否主動攻擊：1=看到就打 0=被打才還手''',
  'SELECT ''npc.agro 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'agro_range') = 0,
  'ALTER TABLE `npc` ADD COLUMN `agro_range` int(10) NOT NULL DEFAULT 6 COMMENT ''主動察覺範圍（格）''',
  'SELECT ''npc.agro_range 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'is_wander') = 0,
  'ALTER TABLE `npc` ADD COLUMN `is_wander` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''閒置時是否在家附近遊走''',
  'SELECT ''npc.is_wander 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'ranged') = 0,
  'ALTER TABLE `npc` ADD COLUMN `ranged` int(10) NOT NULL DEFAULT 1 COMMENT ''普攻距離（格）；1=近戰''',
  'SELECT ''npc.ranged 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'npc' AND COLUMN_NAME = 'idle_chat') = 0,
  'ALTER TABLE `npc` ADD COLUMN `idle_chat` varchar(255) NOT NULL DEFAULT '''' COMMENT ''NPC 閒置時隨機說的話，以 | 分隔''',
  'SELECT ''npc.idle_chat 已存在，略過'' AS info');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 安全區的怪物生成點搬到黑森林中央（範圍 3 格內隨機找可走的位置）
UPDATE `spawnlist_monster`
   SET `mapid` = 1,
       `locx`  = 88 + (`id` MOD 5) * 3,
       `locy`  = 88 + (`id` MOD 4) * 3,
       `range` = 3
 WHERE `mapid` IN (SELECT `map_id` FROM `map` WHERE `safe_zone` = 1);

-- 核對
SELECT `id`, `name`, `mapid`, `locx`, `locy`, `range` FROM `spawnlist_monster` ORDER BY `id`;
