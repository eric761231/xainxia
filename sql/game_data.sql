-- 遊戲策劃資料表（素質成長、境界獎勵、道具）
-- 執行前請確認已建立 characters 表

-- ── 四維素質成長加成 ──
-- stat_type: 1=悟性(stats_intel) 2=神識(stats_spirit) 3=敏捷(stats_agility) 4=體魄(stats_constitution)
CREATE TABLE IF NOT EXISTS `stat_growth_bonus` (
  `stat_type`       TINYINT NOT NULL COMMENT '1=悟性 2=神識 3=敏捷 4=體魄',
  `bonus_type`      VARCHAR(32) NOT NULL COMMENT 'max_hp/hp_regen/max_mp/mp_regen/hit/dodge/puppet_slot/spell_learn_rate/craft_proficiency_rate',
  `bonus_per_point` INT NOT NULL DEFAULT 0 COMMENT '每 1 點素質的加成',
  `note`            VARCHAR(128) DEFAULT NULL,
  PRIMARY KEY (`stat_type`, `bonus_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `stat_growth_bonus` (`stat_type`, `bonus_type`, `bonus_per_point`, `note`) VALUES
  (4, 'max_hp', 10, '體魄：HP 上限'),
  (4, 'hp_regen', 1, '體魄：回血速度'),
  (4, 'defense', 2, '體魄：防禦力'),
  (2, 'max_mp', 10, '神識：MP 上限'),
  (2, 'mp_regen', 1, '神識：回魔速度'),
  (2, 'puppet_slot', 1, '神識：傀儡槽位(上限見 char_create.json)'),
  (3, 'hit', 2, '敏捷：命中'),
  (3, 'dodge', 2, '敏捷：閃避'),
  (1, 'spell_learn_rate', 2, '悟性：法術領悟效率(%)'),
  (1, 'craft_proficiency_rate', 2, '悟性：仙藝熟練度加成(%)')
ON DUPLICATE KEY UPDATE `bonus_per_point` = VALUES(`bonus_per_point`), `note` = VALUES(`note`);

-- ── 境界突破獎勵（大境界提升時累計） ──
CREATE TABLE IF NOT EXISTS `realm_stage_reward` (
  `from_stage`    TINYINT NOT NULL COMMENT '突破前境界 0=鍛體',
  `to_stage`      TINYINT NOT NULL COMMENT '突破後境界 1=練氣',
  `bonus_max_hp`  INT NOT NULL DEFAULT 0,
  `bonus_max_mp`  INT NOT NULL DEFAULT 0,
  `bonus_defense` INT NOT NULL DEFAULT 0,
  `bonus_attack`  INT NOT NULL DEFAULT 0,
  `note`          VARCHAR(128) DEFAULT NULL,
  PRIMARY KEY (`from_stage`, `to_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `realm_stage_reward` VALUES
  (0, 1,  50,  30,  5,  3, '鍛體→練氣'),
  (1, 2,  80,  50,  8,  5, '練氣→築基'),
  (2, 3, 120,  80, 12,  8, '築基→金丹'),
  (3, 4, 160, 110, 16, 10, '金丹→元嬰'),
  (4, 5, 200, 140, 20, 12, '元嬰→化神'),
  (5, 6, 240, 170, 24, 14, '化神→合體'),
  (6, 7, 280, 200, 28, 16, '合體→大乘'),
  (7, 8, 320, 230, 32, 18, '大乘→渡劫'),
  (8, 9, 360, 260, 36, 20, '渡劫→飛升')
ON DUPLICATE KEY UPDATE
  `bonus_max_hp` = VALUES(`bonus_max_hp`), `bonus_max_mp` = VALUES(`bonus_max_mp`),
  `bonus_defense` = VALUES(`bonus_defense`), `bonus_attack` = VALUES(`bonus_attack`);

-- ── 同境界重級獎勵 ──
CREATE TABLE IF NOT EXISTS `realm_level_reward` (
  `realm_stage`     TINYINT NOT NULL COMMENT '0=鍛體期',
  `realm_level`     TINYINT NOT NULL COMMENT '2~10',
  `bonus_max_hp`    INT NOT NULL DEFAULT 0,
  `bonus_max_mp`    INT NOT NULL DEFAULT 0,
  `bonus_defense`   INT NOT NULL DEFAULT 0,
  `bonus_attack`    INT NOT NULL DEFAULT 0,
  `note`            VARCHAR(128) DEFAULT NULL,
  PRIMARY KEY (`realm_stage`, `realm_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 每境界 level 2~10 的通用獎勵模板（可依境界調整）
INSERT INTO `realm_level_reward` (`realm_stage`, `realm_level`, `bonus_max_hp`, `bonus_max_mp`, `bonus_defense`, `bonus_attack`, `note`) VALUES
  (0, 2,  5,  3, 1, 1, '鍛體 Lv2'),
  (0, 3,  5,  3, 1, 1, '鍛體 Lv3'),
  (0, 4,  8,  5, 1, 1, '鍛體 Lv4'),
  (0, 5,  8,  5, 2, 1, '鍛體 Lv5'),
  (0, 6, 10,  6, 2, 2, '鍛體 Lv6'),
  (0, 7, 10,  6, 2, 2, '鍛體 Lv7'),
  (0, 8, 12,  8, 3, 2, '鍛體 Lv8'),
  (0, 9, 12,  8, 3, 2, '鍛體 Lv9'),
  (0, 10, 15, 10, 4, 3, '鍛體 Lv10')
ON DUPLICATE KEY UPDATE
  `bonus_max_hp` = VALUES(`bonus_max_hp`), `bonus_max_mp` = VALUES(`bonus_max_mp`),
  `bonus_defense` = VALUES(`bonus_defense`), `bonus_attack` = VALUES(`bonus_attack`);

-- ── 統一道具表 ──
-- item_type: 0=一般道具 1=武器 2=防具
CREATE TABLE IF NOT EXISTS `item` (
  `item_id`           INT NOT NULL PRIMARY KEY,
  `name`              VARCHAR(64) NOT NULL,
  `item_type`         TINYINT NOT NULL DEFAULT 0 COMMENT '0=道具 1=武器 2=防具',
  `stackable`         TINYINT(1) NOT NULL DEFAULT 1,
  `max_stack`         BIGINT NOT NULL DEFAULT 1,
  `use_type`          TINYINT NOT NULL DEFAULT 0 COMMENT '0=不可使用 1=可使用',
  `weapon_type`       TINYINT NOT NULL DEFAULT 0 COMMENT '劍/刀/槍等',
  `min_damage`        INT NOT NULL DEFAULT 0,
  `max_damage`        INT NOT NULL DEFAULT 0,
  `hit_modifier`      INT NOT NULL DEFAULT 0,
  `armor_type`        TINYINT NOT NULL DEFAULT 0 COMMENT '頭/身/手/腳/盾',
  `ac`                INT NOT NULL DEFAULT 0,
  `damage_reduction`  INT NOT NULL DEFAULT 0,
  `material`          TINYINT NOT NULL DEFAULT 0,
  `note`              VARCHAR(128) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `item` VALUES
  (40308, '金幣',     0, 1, 2000000000, 0, 0, 0, 0, 0, 0, 0, 0, 0, '通用貨幣'),
  (40010, '治癒藥水', 0, 1, 1000, 1, 0, 0, 0, 0, 0, 0, 0, 0, '恢復 HP'),
  (4,     '長劍',     1, 0, 1, 0, 1, 5, 12, 2, 0, 0, 0, 0, '單手劍'),
  (40100, '洗髓丹',   0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '鍛體突破用'),
  (40101, '築基丹',   0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '練氣突破用'),
  (40102, '護脈散',   0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '突破護體')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `item_type` = VALUES(`item_type`);
