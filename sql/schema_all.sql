-- ============================================================================
--  XinServer — 資料庫完整 Schema（單一檔案）
-- ----------------------------------------------------------------------------
--  用途：全新安裝直接執行本檔即可建立所有表與初始資料。
--  結構由實際資料庫匯出，保證與程式一致。
--
--  ⚠ 執行本檔會 DROP 並重建所有表，既有玩家資料會消失。
--
--  含資料的表：伺服器設定、養成規則、道具、地圖、場景物件模板
--  空表：帳號、角色、玩家布置（玩家資料）／spawnlist_npc（待企劃填入）
--  生成點分三張：spawnlist_scene（場景物件）、spawnlist_npc（NPC）、spawnlist_monster（怪物）
--  既有資料庫從舊的單一 spawnlist 升級請執行 sql/migrate_spawnlist_split.sql
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;


-- ════════════════════════════════════════════════════════════
-- 一、伺服器設定
-- 伺服器層級參數（ConfigTable 讀取）
-- ════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS `_config`;
CREATE TABLE `_config` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '資料序號',
  `parameter` varchar(255) COLLATE utf8_bin DEFAULT '' COMMENT '參數名稱',
  `value` varchar(255) COLLATE utf8_bin DEFAULT '' COMMENT '設定值',
  `note` varchar(255) COLLATE utf8_bin DEFAULT '' COMMENT '功能註解',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

INSERT INTO `_config` (`id`, `parameter`, `value`, `note`) VALUES (1,'server_no','1','伺服器編號'),(2,'auto_create_accounts','true','是否自動建立帳號'),(3,'server_name','東勝神州','伺服器名稱'),(4,'max_online_users','500','伺服器人數');

-- ════════════════════════════════════════════════════════════
-- 二、帳號與角色
-- 玩家資料；全新安裝為空表
-- ════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS `accounts`;
CREATE TABLE `accounts` (
  `login_name` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '帳號名稱',
  `password` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '密碼',
  `createTime` datetime DEFAULT NULL COMMENT '創立時間',
  `ip` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '連線IP',
  `macAddress` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '連線主機實體地址',
  `server_no` int(10) DEFAULT NULL COMMENT '伺服器編號',
  `server_name` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '伺服器名稱',
  `online_state` bigint(1) DEFAULT '0' COMMENT '帳號是否連線',
  `access_level` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '帳號權限等級',
  `isBan` bigint(1) DEFAULT '0' COMMENT '帳號是否被禁用',
  `char_slot` int(10) DEFAULT '0' COMMENT '擴增的創角欄位數量',
  PRIMARY KEY (`login_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

DROP TABLE IF EXISTS `characters`;
CREATE TABLE `characters` (
  `account_name` varchar(12) NOT NULL COMMENT '所屬帳號',
  `obj_id` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '全服唯一物件 ID（IdFactory 分配）',
  `char_name` varchar(12) NOT NULL COMMENT '角色名（全服唯一）',
  `sex` tinyint(4) NOT NULL DEFAULT '0' COMMENT '性別：0=男 1=女',
  `attribute` tinyint(4) NOT NULL DEFAULT '0' COMMENT '靈根：0=金 1=木 2=水 3=火 4=土 5=風 6=雷',
  `natal_weapon_id` tinyint(4) NOT NULL DEFAULT '0' COMMENT '本命法寶武器類型',
  `stats_intel` int(11) NOT NULL DEFAULT '10' COMMENT '悟性',
  `stats_spirit` int(11) NOT NULL DEFAULT '10' COMMENT '神識',
  `stats_agility` int(11) NOT NULL DEFAULT '10' COMMENT '敏捷',
  `stats_constitution` int(11) NOT NULL DEFAULT '10' COMMENT '體魄',
  `map_id` int(11) NOT NULL DEFAULT '0' COMMENT '所在地圖',
  `loc_x` int(11) NOT NULL DEFAULT '0' COMMENT 'X 座標',
  `loc_y` int(11) NOT NULL DEFAULT '0' COMMENT 'Y 座標',
  `current_hp` int(11) NOT NULL DEFAULT '0',
  `max_hp` int(11) NOT NULL DEFAULT '0',
  `current_mp` int(11) NOT NULL DEFAULT '0',
  `max_mp` int(11) NOT NULL DEFAULT '0',
  `defense` int(11) NOT NULL DEFAULT '0' COMMENT '防禦力',
  `attack` int(11) NOT NULL DEFAULT '0' COMMENT '攻擊力',
  `hit` int(11) NOT NULL DEFAULT '0' COMMENT '命中',
  `dodge` int(11) NOT NULL DEFAULT '0' COMMENT '閃避',
  `hp_regen` int(11) NOT NULL DEFAULT '0' COMMENT '每回合 HP 回復',
  `mp_regen` int(11) NOT NULL DEFAULT '0' COMMENT '每回合 MP 回復',
  `puppet_max` int(11) NOT NULL DEFAULT '0' COMMENT '傀儡上限',
  `spell_learn_rate` int(11) NOT NULL DEFAULT '100' COMMENT '法術領悟效率（基礎 100）',
  `craft_proficiency_rate` int(11) NOT NULL DEFAULT '100' COMMENT '仙藝熟練度倍率（基礎 100）',
  `exp` int(11) NOT NULL DEFAULT '0' COMMENT '境界內當前經驗值',
  `realm_stage` tinyint(4) NOT NULL DEFAULT '0' COMMENT '境界階段：0=鍛體 … 9=飛昇',
  `realm_level` int(11) NOT NULL DEFAULT '1' COMMENT '境界內小等級（1～levels_per_realm）',
  `faction` varchar(24) NOT NULL DEFAULT '' COMMENT '勢力',
  `life_job` varchar(24) NOT NULL DEFAULT '' COMMENT '生活職業',
  `life_job_level` int(11) NOT NULL DEFAULT '0' COMMENT '生活職業等級',
  `core_technique` varchar(24) NOT NULL DEFAULT '' COMMENT '核心功法',
  PRIMARY KEY (`account_name`,`char_name`),
  UNIQUE KEY `uk_obj_id` (`obj_id`),
  UNIQUE KEY `uk_char_name` (`char_name`),
  KEY `idx_account_name` (`account_name`),
  KEY `idx_map_id` (`map_id`),
  KEY `idx_realm_stage` (`realm_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色資料表';

DROP TABLE IF EXISTS `sequence_id`;
CREATE TABLE `sequence_id` (
  `name` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `next_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

-- ════════════════════════════════════════════════════════════
-- 三、角色養成規則
-- 四維加成、境界定義、突破與升級獎勵、經驗表
-- ════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS `stat_growth_bonus`;
CREATE TABLE `stat_growth_bonus` (
  `stat_type` tinyint(4) NOT NULL COMMENT '素質類型：1=悟性 2=神識 3=敏捷 4=體魄',
  `bonus_type` varchar(32) NOT NULL COMMENT '加成欄位名稱（如 max_hp / hit / spell_learn_rate）',
  `bonus_per_point` int(11) NOT NULL DEFAULT '0' COMMENT '每 1 點素質的數值加成',
  `note` varchar(128) DEFAULT NULL COMMENT '備註',
  PRIMARY KEY (`stat_type`,`bonus_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='四維素質成長加成表';

INSERT INTO `stat_growth_bonus` (`stat_type`, `bonus_type`, `bonus_per_point`, `note`) VALUES (1,'craft_proficiency_rate',2,'悟性：仙藝熟練度加成(%)'),(1,'spell_learn_rate',2,'悟性：法術領悟效率(%)'),(2,'max_mp',10,'神識：MP 上限'),(2,'mp_regen',1,'神識：回魔速度'),(2,'puppet_slot',1,'神識：傀儡槽位（上限見 char_create.json）'),(3,'dodge',2,'敏捷：閃避'),(3,'hit',2,'敏捷：命中'),(4,'defense',2,'體魄：防禦力'),(4,'hp_regen',1,'體魄：回血速度'),(4,'max_hp',10,'體魄：HP 上限');

DROP TABLE IF EXISTS `realm_definition`;
CREATE TABLE `realm_definition` (
  `stage` tinyint(4) NOT NULL COMMENT '境界編號：0=鍛體 … 9=飛昇',
  `name` varchar(16) NOT NULL COMMENT '境界名稱（顯示用）',
  `levels_per_realm` int(11) NOT NULL DEFAULT '10' COMMENT '此境界小等級上限，達到才可嘗試突破',
  PRIMARY KEY (`stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界定義表';

INSERT INTO `realm_definition` (`stage`, `name`, `levels_per_realm`) VALUES (0,'鍛體期',10),(1,'練氣期',10),(2,'築基期',10),(3,'金丹期',10),(4,'元嬰期',10),(5,'化神期',10),(6,'合體期',10),(7,'大乘期',10),(8,'渡劫期',10),(9,'飛昇期',10);

DROP TABLE IF EXISTS `realm_stage_reward`;
CREATE TABLE `realm_stage_reward` (
  `from_stage` tinyint(4) NOT NULL COMMENT '突破前境界：0=鍛體',
  `to_stage` tinyint(4) NOT NULL COMMENT '突破後境界：1=練氣',
  `bonus_max_hp` int(11) NOT NULL DEFAULT '0',
  `bonus_max_mp` int(11) NOT NULL DEFAULT '0',
  `bonus_defense` int(11) NOT NULL DEFAULT '0',
  `bonus_attack` int(11) NOT NULL DEFAULT '0',
  `note` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`from_stage`,`to_stage`),
  KEY `idx_to_stage` (`to_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界突破一次性屬性獎勵表';

INSERT INTO `realm_stage_reward` (`from_stage`, `to_stage`, `bonus_max_hp`, `bonus_max_mp`, `bonus_defense`, `bonus_attack`, `note`) VALUES (0,1,50,30,5,3,'鍛體→練氣'),(1,2,80,50,8,5,'練氣→築基'),(2,3,120,80,12,8,'築基→金丹'),(3,4,160,110,16,10,'金丹→元嬰'),(4,5,200,140,20,12,'元嬰→化神'),(5,6,240,170,24,14,'化神→合體'),(6,7,280,200,28,16,'合體→大乘'),(7,8,320,230,32,18,'大乘→渡劫'),(8,9,360,260,36,20,'渡劫→飛昇');

DROP TABLE IF EXISTS `realm_level_reward`;
CREATE TABLE `realm_level_reward` (
  `realm_stage` tinyint(4) NOT NULL COMMENT '境界編號：0=鍛體',
  `realm_level` tinyint(4) NOT NULL COMMENT '重級（2～levels_per_realm，第 1 重不另給獎勵）',
  `bonus_max_hp` int(11) NOT NULL DEFAULT '0',
  `bonus_max_mp` int(11) NOT NULL DEFAULT '0',
  `bonus_defense` int(11) NOT NULL DEFAULT '0',
  `bonus_attack` int(11) NOT NULL DEFAULT '0',
  `note` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`realm_stage`,`realm_level`),
  KEY `idx_realm_stage` (`realm_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界重級屬性獎勵表';

INSERT INTO `realm_level_reward` (`realm_stage`, `realm_level`, `bonus_max_hp`, `bonus_max_mp`, `bonus_defense`, `bonus_attack`, `note`) VALUES (0,2,5,3,1,1,'鍛體 Lv2'),(0,3,5,3,1,1,'鍛體 Lv3'),(0,4,8,5,1,1,'鍛體 Lv4'),(0,5,8,5,2,1,'鍛體 Lv5'),(0,6,10,6,2,2,'鍛體 Lv6'),(0,7,10,6,2,2,'鍛體 Lv7'),(0,8,12,8,3,2,'鍛體 Lv8'),(0,9,12,8,3,2,'鍛體 Lv9'),(0,10,15,10,4,3,'鍛體 Lv10'),(1,2,8,5,1,1,'練氣 Lv2'),(1,3,8,5,1,1,'練氣 Lv3'),(1,4,12,8,2,2,'練氣 Lv4'),(1,5,12,8,2,2,'練氣 Lv5'),(1,6,15,10,3,2,'練氣 Lv6'),(1,7,15,10,3,2,'練氣 Lv7'),(1,8,18,12,4,3,'練氣 Lv8'),(1,9,18,12,4,3,'練氣 Lv9'),(1,10,22,15,5,4,'練氣 Lv10'),(2,2,12,8,2,2,'築基 Lv2'),(2,3,12,8,2,2,'築基 Lv3'),(2,4,16,11,3,3,'築基 Lv4'),(2,5,16,11,3,3,'築基 Lv5'),(2,6,20,14,4,3,'築基 Lv6'),(2,7,20,14,4,3,'築基 Lv7'),(2,8,24,17,5,4,'築基 Lv8'),(2,9,24,17,5,4,'築基 Lv9'),(2,10,30,20,6,5,'築基 Lv10'),(3,2,16,11,3,2,'金丹 Lv2'),(3,3,16,11,3,2,'金丹 Lv3'),(3,4,20,14,4,3,'金丹 Lv4'),(3,5,20,14,4,3,'金丹 Lv5'),(3,6,25,18,5,4,'金丹 Lv6'),(3,7,25,18,5,4,'金丹 Lv7'),(3,8,30,22,6,5,'金丹 Lv8'),(3,9,30,22,6,5,'金丹 Lv9'),(3,10,38,27,8,6,'金丹 Lv10'),(4,2,20,14,4,3,'元嬰 Lv2'),(4,3,20,14,4,3,'元嬰 Lv3'),(4,4,25,18,5,4,'元嬰 Lv4'),(4,5,25,18,5,4,'元嬰 Lv5'),(4,6,32,23,6,5,'元嬰 Lv6'),(4,7,32,23,6,5,'元嬰 Lv7'),(4,8,38,28,8,6,'元嬰 Lv8'),(4,9,38,28,8,6,'元嬰 Lv9'),(4,10,46,34,10,8,'元嬰 Lv10'),(5,2,25,18,5,4,'化神 Lv2'),(5,3,25,18,5,4,'化神 Lv3'),(5,4,32,23,6,5,'化神 Lv4'),(5,5,32,23,6,5,'化神 Lv5'),(5,6,40,29,8,6,'化神 Lv6'),(5,7,40,29,8,6,'化神 Lv7'),(5,8,48,35,10,8,'化神 Lv8'),(5,9,48,35,10,8,'化神 Lv9'),(5,10,58,42,12,10,'化神 Lv10'),(6,2,32,23,6,5,'合體 Lv2'),(6,3,32,23,6,5,'合體 Lv3'),(6,4,40,29,8,6,'合體 Lv4'),(6,5,40,29,8,6,'合體 Lv5'),(6,6,50,36,10,8,'合體 Lv6'),(6,7,50,36,10,8,'合體 Lv7'),(6,8,60,44,12,10,'合體 Lv8'),(6,9,60,44,12,10,'合體 Lv9'),(6,10,72,52,15,12,'合體 Lv10'),(7,2,40,29,8,6,'大乘 Lv2'),(7,3,40,29,8,6,'大乘 Lv3'),(7,4,50,36,10,8,'大乘 Lv4'),(7,5,50,36,10,8,'大乘 Lv5'),(7,6,62,45,12,10,'大乘 Lv6'),(7,7,62,45,12,10,'大乘 Lv7'),(7,8,74,54,15,12,'大乘 Lv8'),(7,9,74,54,15,12,'大乘 Lv9'),(7,10,90,65,18,15,'大乘 Lv10'),(8,2,50,36,10,8,'渡劫 Lv2'),(8,3,50,36,10,8,'渡劫 Lv3'),(8,4,62,45,12,10,'渡劫 Lv4'),(8,5,62,45,12,10,'渡劫 Lv5'),(8,6,76,55,15,12,'渡劫 Lv6'),(8,7,76,55,15,12,'渡劫 Lv7'),(8,8,92,67,18,15,'渡劫 Lv8'),(8,9,92,67,18,15,'渡劫 Lv9'),(8,10,110,80,22,18,'渡劫 Lv10');

DROP TABLE IF EXISTS `breakthrough_set`;
CREATE TABLE `breakthrough_set` (
  `from_stage` int(11) NOT NULL COMMENT '突破前境界（0=鍛體 … 8=渡劫）',
  `to_stage` int(11) NOT NULL COMMENT '突破後境界（1=練氣 … 9=飛昇）',
  `required_item_ids` varchar(255) NOT NULL DEFAULT '' COMMENT '消耗道具編號陣列（逗號分隔，空字串=不需要）',
  `protect_item_ids` varchar(255) NOT NULL DEFAULT '' COMMENT '護體道具編號陣列（逗號分隔，空字串=無護體選項）',
  `max_realm_level` int(11) NOT NULL DEFAULT '10' COMMENT '突破前需達到的境界最高等級',
  `base_success_rate` int(11) NOT NULL DEFAULT '100' COMMENT '基礎成功機率（0～100）',
  `increase_success_rate` int(11) NOT NULL DEFAULT '0' COMMENT '持有護體道具時的額外成功機率加成（0～100）',
  PRIMARY KEY (`from_stage`),
  KEY `idx_to_stage` (`to_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界突破條件表';

INSERT INTO `breakthrough_set` (`from_stage`, `to_stage`, `required_item_ids`, `protect_item_ids`, `max_realm_level`, `base_success_rate`, `increase_success_rate`) VALUES (0,1,'40100','',10,100,0),(1,2,'40101','40102',10,70,15),(2,3,'40103','',10,60,0),(3,4,'40104','40105',10,50,15),(4,5,'40106','',10,45,0),(5,6,'40107','',10,40,0),(6,7,'40108','',10,35,0),(7,8,'40109','',10,30,0),(8,9,'40110','',10,25,0);

DROP TABLE IF EXISTS `level_exp`;
CREATE TABLE `level_exp` (
  `level` int(11) NOT NULL COMMENT '境界內等級（1 起算）',
  `exp_max` int(11) NOT NULL COMMENT '升至下一重所需總經驗值',
  PRIMARY KEY (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='各等級升級所需經驗值表';

INSERT INTO `level_exp` (`level`, `exp_max`) VALUES (1,100),(2,250),(3,450),(4,700),(5,1000),(6,1400),(7,1900),(8,2500),(9,3200),(10,4000);

-- ════════════════════════════════════════════════════════════
-- 四、道具
-- 道具模板
-- ════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS `item`;
CREATE TABLE `item` (
  `item_id` int(11) NOT NULL COMMENT '道具編號',
  `name` varchar(64) NOT NULL COMMENT '道具名稱',
  `item_type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '類型：0=一般道具 1=武器 2=防具',
  `stackable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '可疊加：1=是',
  `max_stack` bigint(20) NOT NULL DEFAULT '1' COMMENT '最大疊加數量',
  `use_type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '使用方式：0=不可使用 1=可直接使用',
  `weapon_type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '武器類型：0=無 1=劍 2=刀 3=槍…',
  `min_damage` int(11) NOT NULL DEFAULT '0' COMMENT '最小傷害',
  `max_damage` int(11) NOT NULL DEFAULT '0' COMMENT '最大傷害',
  `hit_modifier` int(11) NOT NULL DEFAULT '0' COMMENT '命中修正',
  `armor_type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '防具部位：0=無 1=頭 2=身 3=手 4=腳 5=盾',
  `ac` int(11) NOT NULL DEFAULT '0' COMMENT '防禦值（Armor Class）',
  `damage_reduction` int(11) NOT NULL DEFAULT '0' COMMENT '傷害減免',
  `material` tinyint(4) NOT NULL DEFAULT '0' COMMENT '材質',
  `note` varchar(128) DEFAULT NULL COMMENT '備註',
  PRIMARY KEY (`item_id`),
  KEY `idx_item_type` (`item_type`),
  KEY `idx_name` (`name`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='道具定義表';

INSERT INTO `item` (`item_id`, `name`, `item_type`, `stackable`, `max_stack`, `use_type`, `weapon_type`, `min_damage`, `max_damage`, `hit_modifier`, `armor_type`, `ac`, `damage_reduction`, `material`, `note`) VALUES (4,'長劍',1,0,1,0,1,5,12,2,0,0,0,0,'單手劍'),(40010,'治癒藥水',0,1,1000,1,0,0,0,0,0,0,0,0,'恢復 HP'),(40100,'洗髓丹',0,1,100,1,0,0,0,0,0,0,0,0,'鍛體→練氣突破用'),(40101,'築基丹',0,1,100,1,0,0,0,0,0,0,0,0,'練氣→築基突破用'),(40102,'護脈散',0,1,100,1,0,0,0,0,0,0,0,0,'練氣→築基護體'),(40103,'降塵丹',0,1,100,1,0,0,0,0,0,0,0,0,'築基→金丹突破用'),(40104,'培嬰丹',0,1,100,1,0,0,0,0,0,0,0,0,'金丹→元嬰突破用'),(40105,'定神香',0,1,100,1,0,0,0,0,0,0,0,0,'金丹→元嬰護體'),(40106,'化神丹',0,1,100,1,0,0,0,0,0,0,0,0,'元嬰→化神突破用'),(40107,'太清玉液丹',0,1,100,1,0,0,0,0,0,0,0,0,'化神→合體突破用'),(40108,'法則碎片',0,1,100,1,0,0,0,0,0,0,0,0,'合體→大乘突破用'),(40109,'天劫豁免令',0,1,100,1,0,0,0,0,0,0,0,0,'大乘→渡劫突破用'),(40110,'登仙玉佩',0,1,100,1,0,0,0,0,0,0,0,0,'渡劫→飛昇突破用'),(40308,'金幣',0,1,2000000000,0,0,0,0,0,0,0,0,0,'通用貨幣');

-- ════════════════════════════════════════════════════════════
-- 五、地圖
-- 地圖設定與傳送點。layout_mode 決定場景物件佈局方式
-- ════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS `map`;
CREATE TABLE `map` (
  `map_id` int(11) NOT NULL COMMENT '地圖編號',
  `name` varchar(64) NOT NULL DEFAULT '' COMMENT '地圖顯示名稱',
  `gfxid` int(11) NOT NULL DEFAULT '0' COMMENT '呈現圖片編號（場景背景圖，0=無）',
  `layout_mode` varchar(16) NOT NULL DEFAULT 'static' COMMENT '場景物件佈局：static=固定編寫 random=每局重新隨機 player=玩家佈置',
  `min_x` int(11) NOT NULL DEFAULT '0' COMMENT 'X 座標最小值（邊界）',
  `max_x` int(11) NOT NULL DEFAULT '1000' COMMENT 'X 座標最大值（邊界）',
  `min_y` int(11) NOT NULL DEFAULT '0' COMMENT 'Y 座標最小值（邊界）',
  `max_y` int(11) NOT NULL DEFAULT '1000' COMMENT 'Y 座標最大值（邊界）',
  `safe_zone` tinyint(1) NOT NULL DEFAULT '0' COMMENT '安全區：1=禁止攻擊',
  `pk_enabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'PK 開放：1=允許',
  `description` varchar(255) DEFAULT NULL COMMENT '備註',
  PRIMARY KEY (`map_id`),
  KEY `idx_safe_zone` (`safe_zone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='地圖設定表';

INSERT INTO `map` (`map_id`, `name`, `gfxid`, `layout_mode`, `min_x`, `max_x`, `min_y`, `max_y`, `safe_zone`, `pk_enabled`, `description`) VALUES (0,'修練洞府',0,'static',31,40,31,40,1,0,'出生房間（112x56 格、10x10）'),(1,'黑森林',1,'static',31,150,31,150,0,0,'冒險地區1'),(2,'灰岩山',2,'static',31,50,31,50,0,0,'冒險地區2'),(3,'血獄島',3,'static',31,50,31,50,0,1,'冒險地區3'),(4,'雲雷峰',4,'static',31,50,31,50,0,1,'冒險地區4'),(5,'葬劍島',5,'static',31,50,31,50,0,0,NULL),(6,'斷魂海',6,'static',31,50,31,50,0,0,NULL),(7,'白骨嶺',7,'static',31,50,31,50,0,0,NULL),(8,'天墟山',8,'static',31,50,31,50,0,0,NULL),(9,'碧玉潭',9,'static',31,50,31,50,0,0,NULL),(10,'千月湖',10,'static',31,50,31,50,0,0,NULL),(11,'赤血海',11,'static',31,50,31,50,0,0,NULL),(12,'落霞峰',12,'static',31,50,31,50,0,0,NULL),(13,'九幽山',13,'static',31,50,31,50,0,0,NULL),(14,'風嘯原',14,'static',31,50,31,50,0,0,NULL),(15,'青木原',15,'static',31,50,31,50,0,0,NULL);

DROP TABLE IF EXISTS `map_portal`;
CREATE TABLE `map_portal` (
  `portal_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '傳送點編號',
  `map_id` int(11) NOT NULL COMMENT '所在地圖編號',
  `loc_x` int(11) NOT NULL DEFAULT '0' COMMENT '傳送點 X 座標（前端小地圖藍色光點）',
  `loc_y` int(11) NOT NULL DEFAULT '0' COMMENT '傳送點 Y 座標',
  `dest_map_id` int(11) NOT NULL COMMENT '目標地圖編號',
  `dest_x` int(11) NOT NULL DEFAULT '0' COMMENT '目標 X 座標',
  `dest_y` int(11) NOT NULL DEFAULT '0' COMMENT '目標 Y 座標',
  `trigger_range` int(11) NOT NULL DEFAULT '3' COMMENT '觸發範圍（格數，Chebyshev 距離 ≤ 此值可使用）',
  `dest_heading` int(11) NOT NULL DEFAULT '-1' COMMENT '到達面向 0..7；-1=保留玩家當下面向',
  `name` varchar(64) NOT NULL DEFAULT '' COMMENT '傳送點顯示名稱（如：前往青雲山）',
  PRIMARY KEY (`portal_id`),
  KEY `idx_map_id` (`map_id`),
  KEY `idx_dest_map_id` (`dest_map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='地圖傳送點表';

-- ════════════════════════════════════════════════════════════
-- 六、世界物件
-- NPC/怪物模板、場景物件模板、生成點（企劃編寫的世界內容）
-- ════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS `npc`;
CREATE TABLE `npc` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '資料序號',
  `npc_id` int(10) unsigned DEFAULT NULL COMMENT 'npc編號',
  `name` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '名稱註解',
  `type_name` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT 'npc類型分類代號',
  `gfxid` int(10) DEFAULT '0' COMMENT '外型編號',
  `maxhp` int(10) DEFAULT '0' COMMENT '最大體力',
  `maxmp` int(10) DEFAULT '0' COMMENT '最大法力',
  `defense` int(10) DEFAULT '0' COMMENT '防禦力',
  `base_damage` int(10) DEFAULT '10' COMMENT '基礎傷害',
  `rand_damage` int(10) DEFAULT '0' COMMENT '浮動傷害',
  `hit` int(10) NOT NULL DEFAULT '0' COMMENT '命中',
  `dodge` int(10) NOT NULL DEFAULT '0' COMMENT '閃避',
  `passispeed` int(10) NOT NULL DEFAULT '800' COMMENT '走一格的毫秒數；前端插值約 400ms，不可低於 400',
  `atkspeed` int(10) NOT NULL DEFAULT '1200' COMMENT '攻擊一次的毫秒數',
  `agro` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否主動攻擊：1=看到就打 0=被打才還手',
  `agro_range` int(10) NOT NULL DEFAULT '6' COMMENT '主動察覺範圍（格）',
  `is_wander` tinyint(1) NOT NULL DEFAULT '1' COMMENT '閒置時是否在家附近遊走',
  `ranged` int(10) NOT NULL DEFAULT '1' COMMENT '普攻距離（格）；1=近戰',
  `idle_chat` varchar(255) NOT NULL DEFAULT '' COMMENT 'NPC 閒置時隨機說的話，以 | 分隔',
  `actionList` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '動作代號列表',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

-- 測試用怪物。沒有這兩筆的話 npc 表是空的，地圖上不會有任何可攻擊的目標，
-- 戰鬥流程等於無法驗收。
INSERT INTO `npc` (`npc_id`,`name`,`type_name`,`gfxid`,`maxhp`,`maxmp`,`defense`,`base_damage`,`rand_damage`,`actionList`) VALUES
 (45000,'山野狼','monster',1,40,0,0,4,3,''),
 (45001,'洞穴蝠','monster',2,25,0,0,3,2,'');

DROP TABLE IF EXISTS `property`;
CREATE TABLE `property` (
  `id` int(11) NOT NULL COMMENT '場景物件編號',
  `pngid` int(11) NOT NULL DEFAULT '0' COMMENT '圖片編號，對應前端 assets/data/object_catalog.json 的物件 id（1001~3009）',
  `blocking` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否阻擋通行：0=可穿越 1=擋路',
  `footprint_w` int(11) NOT NULL DEFAULT '1' COMMENT '碰撞佔格寬（地面格數，非視覺尺寸）',
  `footprint_h` int(11) NOT NULL DEFAULT '1' COMMENT '碰撞佔格高（地面格數，非視覺尺寸）',
  `min_gap` int(11) NOT NULL DEFAULT '0' COMMENT '同類物件最小間隔格數（0=不限制），random 佈局用',
  `placeable` tinyint(1) NOT NULL DEFAULT '0' COMMENT '玩家可否自行放置',
  `placement` varchar(8) NOT NULL DEFAULT 'floor' COMMENT '放置面：floor/wall/any',
  `view_note` varchar(64) NOT NULL DEFAULT '' COMMENT '顯示名稱',
  `action` tinyint(1) NOT NULL DEFAULT '0' COMMENT '可否互動：0=不可互動 1=可互動',
  `action_type` int(11) NOT NULL DEFAULT '0' COMMENT '互動方式：1=對話 2=採集',
  `value` int(11) NOT NULL DEFAULT '0' COMMENT '進度條之類的數值',
  `bubble_text` varchar(255) NOT NULL DEFAULT '' COMMENT '對話內容（互動時才由 S_BUBBLE_DIALOG 送出）',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='場景物件設定表';

INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (1200,1200,1,2,3,0,0,'floor','木桌一',0,0,0,''),(1201,1201,1,3,2,0,0,'floor','木桌二',0,0,0,'');
-- placeable 先關著：這兩筆的美術（table001.png / table002.png）從未進過版控，
-- 開著會讓玩家放置清單列出放下去是綠色色塊的東西。補圖後改回 1。
-- （原本的升級 patch 已移除，完整設定以本檔為準）

-- 地圖 0「修練洞府」固定擺設。pngid 對應前端 object_catalog.json 的同號物件，
-- footprint_w/h 與 catalog 的 footprint 逐項相同 —— 碰撞由這份決定、接地陰影由
-- catalog 決定，不一致就會「看得到卻走得過去」。
-- 舊的 4001～4008 已連同美術一起淘汰，不再建立模板
-- （原本的升級 patch 已移除，完整設定以本檔為準）。
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES
(4101,4101,1,1,3,0,0,'floor','洞府書櫃（左牆）',0,0,0,''),
(4102,4102,1,1,1,0,0,'floor','白蘭花盆',0,0,0,''),
(4103,4103,1,1,1,0,0,'floor','松樹盆景',0,0,0,''),
(4104,4104,1,3,1,0,0,'floor','紅楓長盆',0,0,0,''),
(4105,4105,1,2,1,0,0,'floor','靈石竹簡櫃',0,0,0,''),
(4106,4106,1,1,1,0,0,'floor','直立綠植',0,0,0,''),
(4107,4107,0,1,1,0,0,'floor','聚靈法陣',0,0,0,'');

-- 黑森林（map 1）植被。完整設定（範圍、模板、生成點）在 sql/map1_black_forest.sql，
-- 下面的模板必須與那份一致；缺模板時 SpawnTable 每筆都 warn「找不到場景物件模板」、整張圖沒有植被。
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES
(5001,5001,1,2,2,0,0,'floor','古橡',0,0,0,''),
(5002,5002,1,2,2,0,0,'floor','虯松',0,0,0,''),
(5003,5003,1,2,2,0,0,'floor','苔榆',0,0,0,''),
(5004,5004,1,2,2,0,0,'floor','枯枒',0,0,0,''),
(5005,5005,1,1,1,0,0,'floor','苔樹樁',0,0,0,''),
(5006,5006,1,2,1,0,0,'floor','倒木',0,0,0,''),
(5007,5007,1,1,1,0,0,'floor','暗叢',0,0,0,''),
(5008,5008,1,1,1,0,0,'floor','棘蔓',0,0,0,''),
(5009,5009,0,1,1,0,0,'floor','蕨',0,0,0,''),
(5010,5010,0,1,1,0,0,'floor','深草',0,0,0,''),
(5011,5011,0,1,1,0,0,'floor','白花',0,0,0,''),
(5012,5012,0,1,1,0,0,'floor','紫花',0,0,0,''),
(5013,5013,0,1,1,0,0,'floor','幽藍花',0,0,0,''),
(5014,5014,0,1,1,0,0,'floor','褐菇',0,0,0,''),
(5015,5015,0,1,1,0,0,'floor','枯草叢',0,0,0,''),
(5016,5016,1,1,1,0,0,'floor','苔石',0,0,0,'');

-- 生成點分三張表：場景物件／NPC／怪物（舊的單一 spawnlist 已淘汰）
DROP TABLE IF EXISTS `spawnlist`;

DROP TABLE IF EXISTS `spawnlist_scene`;
CREATE TABLE `spawnlist_scene` (
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

DROP TABLE IF EXISTS `spawnlist_npc`;
CREATE TABLE `spawnlist_npc` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '資料序號',
  `zone` varchar(255) DEFAULT NULL COMMENT '地區註解',
  `npc_id` int(10) NOT NULL COMMENT 'NPC模板（npc.npc_id）',
  `name` varchar(255) DEFAULT NULL COMMENT '名稱註解',
  `count` int(10) NOT NULL DEFAULT '1' COMMENT '數量',
  `locx` int(10) NOT NULL COMMENT '中心X座標',
  `locy` int(10) NOT NULL COMMENT '中心Y座標',
  `range` int(10) NOT NULL DEFAULT '0' COMMENT '散佈範圍（0=固定座標）',
  `mapid` int(10) NOT NULL DEFAULT '0' COMMENT '地圖編號',
  `heading` int(10) NOT NULL DEFAULT '2' COMMENT '初始面向 0..7；-1=隨機',
  PRIMARY KEY (`id`),
  KEY `idx_mapid` (`mapid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='NPC生成點';

DROP TABLE IF EXISTS `spawnlist_monster`;
CREATE TABLE `spawnlist_monster` (
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
  `respawn_delay_random` int(10) NOT NULL DEFAULT '0' COMMENT '重生延遲隨機加值（秒）：實際 = respawn_delay + rand(0..此值)',
  `movement_distance` int(10) NOT NULL DEFAULT '12' COMMENT '離家最大距離（格），超過就脫戰回家；0=不限制',
  `heading` int(10) NOT NULL DEFAULT '2' COMMENT '初始面向 0..7；-1=隨機',
  `spawn_type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0=一般 1=首領（固定座標不散佈）',
  PRIMARY KEY (`id`),
  KEY `idx_mapid` (`mapid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='怪物生成點';

-- 修練洞府（map 0）：牆面由完整背景 assets/maps/0.png 繪製，
-- 不把兩片帶端柱的 wall.png 當獨立物件重疊，避免轉角柱變成雙影。
-- 固定擺設為左牆兩座書櫃與白蘭花、後角松樹、右牆紅楓長盆／靈石竹簡櫃／直立綠植，
-- 加上中央的聚靈法陣；中央法陣與入口到法陣的動線保持淨空。
-- static 地圖的 range=0 代表座標固定；位置均在 map 0 的合法範圍 31..50 內。
-- 與 sql/map0_cave.sql 同一份布置（那支是既有資料庫的升級用）。
INSERT INTO `spawnlist_scene` (`zone`, `property_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`) VALUES
('修練洞府',4103,'松樹盆景',1,32,32,0,0),
('修練洞府',4104,'紅楓長盆',1,34,31,0,0),
('修練洞府',4105,'靈石竹簡櫃',1,39,31,0,0),
('修練洞府',4106,'直立綠植',1,40,31,0,0),
('修練洞府',4101,'洞府書櫃（內）',1,31,34,0,0),
('修練洞府',4101,'洞府書櫃（外）',1,31,39,0,0),
('修練洞府',4102,'白蘭花盆',1,31,40,0,0),
('修練洞府',4107,'聚靈法陣',1,35,35,0,0);
-- 測試怪物：生在黑森林（地圖 1）中央的開闊區域。
-- 修練洞府是安全區（safe_zone=1），伺服器不會在安全區生怪。
INSERT INTO `spawnlist_monster` (`zone`,`npc_id`,`name`,`count`,`locx`,`locy`,`range`,`mapid`,`respawn_delay`) VALUES
 ('黑森林',45000,'山野狼',1,90,90,3,1,15),
 ('黑森林',45000,'山野狼',1,94,93,3,1,15),
 ('黑森林',45001,'洞穴蝠',1,88,96,3,1,15);


-- ════════════════════════════════════════════════════════════
-- 七、玩家布置
-- 角色自己擺的家具；與 spawnlist_scene 的世界物件完全分離
-- ════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS `character_decoration`;
CREATE TABLE `character_decoration` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `char_name` varchar(12) NOT NULL,
  `property_id` int(11) NOT NULL,
  `map_id` int(11) NOT NULL,
  `loc_x` int(11) NOT NULL,
  `loc_y` int(11) NOT NULL,
  `offset_x` int(11) NOT NULL DEFAULT '0',
  `offset_y` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_owner_map` (`char_name`,`map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 角色背包。道具實例的持久化 —— 在此之前 Inventory 只存在記憶體，
-- 登出即消失，所以突破的道具消耗只能永遠放行（見 BreakthroughTemplate 的 TODO）。
DROP TABLE IF EXISTS `character_items`;
CREATE TABLE `character_items` (
  `obj_id` bigint(20) unsigned NOT NULL COMMENT '道具實例 ID（IdFactory 分配）',
  `char_obj_id` bigint(20) unsigned NOT NULL COMMENT '擁有者角色的 obj_id',
  `item_id` int(11) NOT NULL COMMENT '道具編號（→ item.item_id）',
  `count` bigint(20) NOT NULL DEFAULT '1' COMMENT '數量（可疊加道具才會 > 1）',
  `enchant_level` int(11) NOT NULL DEFAULT '0' COMMENT '強化等級',
  `bless` int(11) NOT NULL DEFAULT '1' COMMENT '祝福狀態',
  `durability` int(11) NOT NULL DEFAULT '0' COMMENT '耐久',
  `is_equipped` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否裝備中',
  `is_identified` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否已鑑定',
  PRIMARY KEY (`obj_id`),
  KEY `idx_owner` (`char_obj_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色背包';

-- 地圖逐格地形碰撞（牆／水／懸崖）。與場景物件佔格分開：物件會被移除，地形不會。
DROP TABLE IF EXISTS `map_collision`;
CREATE TABLE `map_collision` (
  `map_id` int(11) NOT NULL,
  `loc_x` int(11) NOT NULL,
  `loc_y` int(11) NOT NULL,
  PRIMARY KEY (`map_id`,`loc_x`,`loc_y`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 物件 ID 序列起始值（IdFactory 啟動時讀取）
INSERT INTO `sequence_id` (`name`, `next_id`) VALUES ('obj_id', 10000);

SET FOREIGN_KEY_CHECKS = 1;
