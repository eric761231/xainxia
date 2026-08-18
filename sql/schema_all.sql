-- ============================================================
-- XinServer — 遊戲資料庫完整 Schema
-- 版本：整合至 game_data_v4 + map_data（含所有遷移後的最終欄位）
-- 用途：全新安裝時直接執行此檔案建立所有表與初始資料
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ════════════════════════════════════════════════════════════
-- 1. 角色表
-- 索引設計：
--   PK  (account_name, char_name)  — 帳號下查角色
--   UQ  obj_id                     — 物件系統 World.get().storeObject(pc) 唯一性
--   UQ  char_name                  — 全服角色名唯一，創角 / 選角檢查
--   IDX account_name               — 查詢某帳號的角色列表
--   IDX map_id                     — 地圖廣播：找出在同一張地圖的角色
--   IDX realm_stage                — GM 統計 / 境界篩選
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `characters`;
CREATE TABLE `characters` (
  -- ── 身份 ──────────────────────────────────────────────────
  `account_name`          VARCHAR(12)   NOT NULL              COMMENT '所屬帳號',
  `obj_id`                BIGINT UNSIGNED NOT NULL DEFAULT 0  COMMENT '全服唯一物件 ID（IdFactory 分配）',
  `char_name`             VARCHAR(12)   NOT NULL              COMMENT '角色名（全服唯一）',
  `sex`                   TINYINT       NOT NULL DEFAULT 0    COMMENT '性別：0=男 1=女',
  `attribute`             TINYINT       NOT NULL DEFAULT 0    COMMENT '靈根：0=金 1=木 2=水 3=火 4=土 5=風 6=雷',
  `natal_weapon_id`       TINYINT       NOT NULL DEFAULT 0    COMMENT '本命法寶武器類型',
  -- ── 四維素質 ──────────────────────────────────────────────
  `stats_intel`           INT           NOT NULL DEFAULT 10   COMMENT '悟性',
  `stats_spirit`          INT           NOT NULL DEFAULT 10   COMMENT '神識',
  `stats_agility`         INT           NOT NULL DEFAULT 10   COMMENT '敏捷',
  `stats_constitution`    INT           NOT NULL DEFAULT 10   COMMENT '體魄',
  -- ── 位置 ──────────────────────────────────────────────────
  `map_id`                INT           NOT NULL DEFAULT 0    COMMENT '所在地圖',
  `loc_x`                 INT           NOT NULL DEFAULT 0    COMMENT 'X 座標',
  `loc_y`                 INT           NOT NULL DEFAULT 0    COMMENT 'Y 座標',
  -- ── 生命 / 魔力 ───────────────────────────────────────────
  `current_hp`            INT           NOT NULL DEFAULT 0,
  `max_hp`                INT           NOT NULL DEFAULT 0,
  `current_mp`            INT           NOT NULL DEFAULT 0,
  `max_mp`                INT           NOT NULL DEFAULT 0,
  -- ── 衍生戰鬥屬性 ──────────────────────────────────────────
  `defense`               INT           NOT NULL DEFAULT 0    COMMENT '防禦力',
  `attack`                INT           NOT NULL DEFAULT 0    COMMENT '攻擊力',
  `hit`                   INT           NOT NULL DEFAULT 0    COMMENT '命中',
  `dodge`                 INT           NOT NULL DEFAULT 0    COMMENT '閃避',
  `hp_regen`              INT           NOT NULL DEFAULT 0    COMMENT '每回合 HP 回復',
  `mp_regen`              INT           NOT NULL DEFAULT 0    COMMENT '每回合 MP 回復',
  `puppet_max`            INT           NOT NULL DEFAULT 0    COMMENT '傀儡上限',
  `spell_learn_rate`      INT           NOT NULL DEFAULT 100  COMMENT '法術領悟效率（基礎 100）',
  `craft_proficiency_rate` INT          NOT NULL DEFAULT 100  COMMENT '仙藝熟練度倍率（基礎 100）',
  -- ── 成長 ──────────────────────────────────────────────────
  `exp`                   INT           NOT NULL DEFAULT 0    COMMENT '境界內當前經驗值',
  `realm_stage`           TINYINT       NOT NULL DEFAULT 0    COMMENT '境界階段：0=鍛體 … 9=飛昇',
  `realm_level`           INT           NOT NULL DEFAULT 1    COMMENT '境界內小等級（1～levels_per_realm）',
  -- ── 職業 / 勢力 ───────────────────────────────────────────
  `faction`               VARCHAR(24)   NOT NULL DEFAULT ''   COMMENT '勢力',
  `life_job`              VARCHAR(24)   NOT NULL DEFAULT ''   COMMENT '生活職業',
  `life_job_level`        INT           NOT NULL DEFAULT 0    COMMENT '生活職業等級',
  `core_technique`        VARCHAR(24)   NOT NULL DEFAULT ''   COMMENT '核心功法',
  -- ── 索引 ──────────────────────────────────────────────────
  PRIMARY KEY (`account_name`, `char_name`),
  UNIQUE  KEY `uk_obj_id`       (`obj_id`),
  UNIQUE  KEY `uk_char_name`    (`char_name`),
  KEY         `idx_account_name` (`account_name`),
  KEY         `idx_map_id`       (`map_id`),
  KEY         `idx_realm_stage`  (`realm_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色資料表';


-- ════════════════════════════════════════════════════════════
-- 2. 四維素質成長加成表
-- 固定 10 筆，PK 已足夠（stat_type + bonus_type 為複合精確查詢）
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `stat_growth_bonus`;
CREATE TABLE `stat_growth_bonus` (
  `stat_type`       TINYINT      NOT NULL COMMENT '素質類型：1=悟性 2=神識 3=敏捷 4=體魄',
  `bonus_type`      VARCHAR(32)  NOT NULL COMMENT '加成欄位名稱（如 max_hp / hit / spell_learn_rate）',
  `bonus_per_point` INT          NOT NULL DEFAULT 0  COMMENT '每 1 點素質的數值加成',
  `note`            VARCHAR(128) DEFAULT NULL         COMMENT '備註',
  PRIMARY KEY (`stat_type`, `bonus_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='四維素質成長加成表';

INSERT INTO `stat_growth_bonus` (`stat_type`, `bonus_type`, `bonus_per_point`, `note`) VALUES
  (1, 'spell_learn_rate',      2, '悟性：法術領悟效率(%)'),
  (1, 'craft_proficiency_rate',2, '悟性：仙藝熟練度加成(%)'),
  (2, 'max_mp',                10,'神識：MP 上限'),
  (2, 'mp_regen',               1,'神識：回魔速度'),
  (2, 'puppet_slot',            1,'神識：傀儡槽位（上限見 char_create.json）'),
  (3, 'hit',                    2,'敏捷：命中'),
  (3, 'dodge',                  2,'敏捷：閃避'),
  (4, 'max_hp',                10,'體魄：HP 上限'),
  (4, 'hp_regen',               1,'體魄：回血速度'),
  (4, 'defense',                2,'體魄：防禦力')
ON DUPLICATE KEY UPDATE
  `bonus_per_point` = VALUES(`bonus_per_point`),
  `note`            = VALUES(`note`);


-- ════════════════════════════════════════════════════════════
-- 3. 境界突破獎勵表（突破至新境界時一次性加成）
-- 索引設計：
--   PK  (from_stage, to_stage)   — 主要查詢鍵
--   IDX to_stage                 — sumUpToStage：WHERE to_stage <= ? 範圍掃描
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `realm_stage_reward`;
CREATE TABLE `realm_stage_reward` (
  `from_stage`    TINYINT      NOT NULL COMMENT '突破前境界：0=鍛體',
  `to_stage`      TINYINT      NOT NULL COMMENT '突破後境界：1=練氣',
  `bonus_max_hp`  INT          NOT NULL DEFAULT 0,
  `bonus_max_mp`  INT          NOT NULL DEFAULT 0,
  `bonus_defense` INT          NOT NULL DEFAULT 0,
  `bonus_attack`  INT          NOT NULL DEFAULT 0,
  `note`          VARCHAR(128) DEFAULT NULL,
  PRIMARY KEY (`from_stage`, `to_stage`),
  KEY `idx_to_stage` (`to_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界突破一次性屬性獎勵表';

INSERT INTO `realm_stage_reward`
  (`from_stage`, `to_stage`, `bonus_max_hp`, `bonus_max_mp`, `bonus_defense`, `bonus_attack`, `note`)
VALUES
  (0, 1,  50,  30,  5,  3, '鍛體→練氣'),
  (1, 2,  80,  50,  8,  5, '練氣→築基'),
  (2, 3, 120,  80, 12,  8, '築基→金丹'),
  (3, 4, 160, 110, 16, 10, '金丹→元嬰'),
  (4, 5, 200, 140, 20, 12, '元嬰→化神'),
  (5, 6, 240, 170, 24, 14, '化神→合體'),
  (6, 7, 280, 200, 28, 16, '合體→大乘'),
  (7, 8, 320, 230, 32, 18, '大乘→渡劫'),
  (8, 9, 360, 260, 36, 20, '渡劫→飛昇')
ON DUPLICATE KEY UPDATE
  `bonus_max_hp`  = VALUES(`bonus_max_hp`),
  `bonus_max_mp`  = VALUES(`bonus_max_mp`),
  `bonus_defense` = VALUES(`bonus_defense`),
  `bonus_attack`  = VALUES(`bonus_attack`);


-- ════════════════════════════════════════════════════════════
-- 4. 境界重級獎勵表（同境界每升一重時加成）
-- 索引設計：
--   PK  (realm_stage, realm_level) — 精確查詢；sumUpToLevel 順序掃描
--   IDX realm_stage                — 只查某境界全部重級時效率更高
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `realm_level_reward`;
CREATE TABLE `realm_level_reward` (
  `realm_stage`   TINYINT      NOT NULL COMMENT '境界編號：0=鍛體',
  `realm_level`   TINYINT      NOT NULL COMMENT '重級（2～levels_per_realm，第 1 重不另給獎勵）',
  `bonus_max_hp`  INT          NOT NULL DEFAULT 0,
  `bonus_max_mp`  INT          NOT NULL DEFAULT 0,
  `bonus_defense` INT          NOT NULL DEFAULT 0,
  `bonus_attack`  INT          NOT NULL DEFAULT 0,
  `note`          VARCHAR(128) DEFAULT NULL,
  PRIMARY KEY (`realm_stage`, `realm_level`),
  KEY `idx_realm_stage` (`realm_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界重級屬性獎勵表';

INSERT INTO `realm_level_reward`
  (`realm_stage`, `realm_level`, `bonus_max_hp`, `bonus_max_mp`, `bonus_defense`, `bonus_attack`, `note`)
VALUES
  -- 鍛體期（stage=0）Lv2~10
  (0,  2,  5,  3, 1, 1, '鍛體 Lv2'),
  (0,  3,  5,  3, 1, 1, '鍛體 Lv3'),
  (0,  4,  8,  5, 1, 1, '鍛體 Lv4'),
  (0,  5,  8,  5, 2, 1, '鍛體 Lv5'),
  (0,  6, 10,  6, 2, 2, '鍛體 Lv6'),
  (0,  7, 10,  6, 2, 2, '鍛體 Lv7'),
  (0,  8, 12,  8, 3, 2, '鍛體 Lv8'),
  (0,  9, 12,  8, 3, 2, '鍛體 Lv9'),
  (0, 10, 15, 10, 4, 3, '鍛體 Lv10'),
  -- 練氣期（stage=1）Lv2~10
  (1,  2,  8,  5, 1, 1, '練氣 Lv2'),
  (1,  3,  8,  5, 1, 1, '練氣 Lv3'),
  (1,  4, 12,  8, 2, 2, '練氣 Lv4'),
  (1,  5, 12,  8, 2, 2, '練氣 Lv5'),
  (1,  6, 15, 10, 3, 2, '練氣 Lv6'),
  (1,  7, 15, 10, 3, 2, '練氣 Lv7'),
  (1,  8, 18, 12, 4, 3, '練氣 Lv8'),
  (1,  9, 18, 12, 4, 3, '練氣 Lv9'),
  (1, 10, 22, 15, 5, 4, '練氣 Lv10'),
  -- 築基期（stage=2）Lv2~10
  (2,  2, 12,  8, 2, 2, '築基 Lv2'),
  (2,  3, 12,  8, 2, 2, '築基 Lv3'),
  (2,  4, 16, 11, 3, 3, '築基 Lv4'),
  (2,  5, 16, 11, 3, 3, '築基 Lv5'),
  (2,  6, 20, 14, 4, 3, '築基 Lv6'),
  (2,  7, 20, 14, 4, 3, '築基 Lv7'),
  (2,  8, 24, 17, 5, 4, '築基 Lv8'),
  (2,  9, 24, 17, 5, 4, '築基 Lv9'),
  (2, 10, 30, 20, 6, 5, '築基 Lv10'),
  -- 金丹期（stage=3）Lv2~10
  (3,  2, 16, 11, 3, 2, '金丹 Lv2'),
  (3,  3, 16, 11, 3, 2, '金丹 Lv3'),
  (3,  4, 20, 14, 4, 3, '金丹 Lv4'),
  (3,  5, 20, 14, 4, 3, '金丹 Lv5'),
  (3,  6, 25, 18, 5, 4, '金丹 Lv6'),
  (3,  7, 25, 18, 5, 4, '金丹 Lv7'),
  (3,  8, 30, 22, 6, 5, '金丹 Lv8'),
  (3,  9, 30, 22, 6, 5, '金丹 Lv9'),
  (3, 10, 38, 27, 8, 6, '金丹 Lv10'),
  -- 元嬰期（stage=4）Lv2~10
  (4,  2, 20, 14, 4, 3, '元嬰 Lv2'),
  (4,  3, 20, 14, 4, 3, '元嬰 Lv3'),
  (4,  4, 25, 18, 5, 4, '元嬰 Lv4'),
  (4,  5, 25, 18, 5, 4, '元嬰 Lv5'),
  (4,  6, 32, 23, 6, 5, '元嬰 Lv6'),
  (4,  7, 32, 23, 6, 5, '元嬰 Lv7'),
  (4,  8, 38, 28, 8, 6, '元嬰 Lv8'),
  (4,  9, 38, 28, 8, 6, '元嬰 Lv9'),
  (4, 10, 46, 34,10, 8, '元嬰 Lv10'),
  -- 化神期（stage=5）Lv2~10
  (5,  2, 25, 18, 5, 4, '化神 Lv2'),
  (5,  3, 25, 18, 5, 4, '化神 Lv3'),
  (5,  4, 32, 23, 6, 5, '化神 Lv4'),
  (5,  5, 32, 23, 6, 5, '化神 Lv5'),
  (5,  6, 40, 29, 8, 6, '化神 Lv6'),
  (5,  7, 40, 29, 8, 6, '化神 Lv7'),
  (5,  8, 48, 35,10, 8, '化神 Lv8'),
  (5,  9, 48, 35,10, 8, '化神 Lv9'),
  (5, 10, 58, 42,12,10, '化神 Lv10'),
  -- 合體期（stage=6）Lv2~10
  (6,  2, 32, 23, 6, 5, '合體 Lv2'),
  (6,  3, 32, 23, 6, 5, '合體 Lv3'),
  (6,  4, 40, 29, 8, 6, '合體 Lv4'),
  (6,  5, 40, 29, 8, 6, '合體 Lv5'),
  (6,  6, 50, 36,10, 8, '合體 Lv6'),
  (6,  7, 50, 36,10, 8, '合體 Lv7'),
  (6,  8, 60, 44,12,10, '合體 Lv8'),
  (6,  9, 60, 44,12,10, '合體 Lv9'),
  (6, 10, 72, 52,15,12, '合體 Lv10'),
  -- 大乘期（stage=7）Lv2~10
  (7,  2, 40, 29, 8, 6, '大乘 Lv2'),
  (7,  3, 40, 29, 8, 6, '大乘 Lv3'),
  (7,  4, 50, 36,10, 8, '大乘 Lv4'),
  (7,  5, 50, 36,10, 8, '大乘 Lv5'),
  (7,  6, 62, 45,12,10, '大乘 Lv6'),
  (7,  7, 62, 45,12,10, '大乘 Lv7'),
  (7,  8, 74, 54,15,12, '大乘 Lv8'),
  (7,  9, 74, 54,15,12, '大乘 Lv9'),
  (7, 10, 90, 65,18,15, '大乘 Lv10'),
  -- 渡劫期（stage=8）Lv2~10
  (8,  2,  50,  36,10, 8, '渡劫 Lv2'),
  (8,  3,  50,  36,10, 8, '渡劫 Lv3'),
  (8,  4,  62,  45,12,10, '渡劫 Lv4'),
  (8,  5,  62,  45,12,10, '渡劫 Lv5'),
  (8,  6,  76,  55,15,12, '渡劫 Lv6'),
  (8,  7,  76,  55,15,12, '渡劫 Lv7'),
  (8,  8,  92,  67,18,15, '渡劫 Lv8'),
  (8,  9,  92,  67,18,15, '渡劫 Lv9'),
  (8, 10, 110,  80,22,18, '渡劫 Lv10')
ON DUPLICATE KEY UPDATE
  `bonus_max_hp`  = VALUES(`bonus_max_hp`),
  `bonus_max_mp`  = VALUES(`bonus_max_mp`),
  `bonus_defense` = VALUES(`bonus_defense`),
  `bonus_attack`  = VALUES(`bonus_attack`);


-- ════════════════════════════════════════════════════════════
-- 5. 境界定義表
-- 固定 10 筆，PK 精確查詢已足夠
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `realm_definition`;
CREATE TABLE `realm_definition` (
  `stage`            TINYINT     NOT NULL COMMENT '境界編號：0=鍛體 … 9=飛昇',
  `name`             VARCHAR(16) NOT NULL COMMENT '境界名稱（顯示用）',
  `levels_per_realm` INT         NOT NULL DEFAULT 10 COMMENT '此境界小等級上限，達到才可嘗試突破',
  PRIMARY KEY (`stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界定義表';

INSERT INTO `realm_definition` (`stage`, `name`, `levels_per_realm`) VALUES
  (0, '鍛體期', 10),
  (1, '練氣期', 10),
  (2, '築基期', 10),
  (3, '金丹期', 10),
  (4, '元嬰期', 10),
  (5, '化神期', 10),
  (6, '合體期', 10),
  (7, '大乘期', 10),
  (8, '渡劫期', 10),
  (9, '飛昇期', 10)
ON DUPLICATE KEY UPDATE
  `name`             = VALUES(`name`),
  `levels_per_realm` = VALUES(`levels_per_realm`);


-- ════════════════════════════════════════════════════════════
-- 6. 境界突破條件表（最終結構，整合 v2 + v4 遷移）
-- 索引設計：
--   PK  from_stage               — 主要查詢：BreakthroughRequirementTable.getRequirement(fromStage)
--   IDX to_stage                 — 反向查詢：「哪個境界可突破至此」（GM 工具 / 策劃調整用）
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `breakthrough_set`;
CREATE TABLE `breakthrough_set` (
  `from_stage`           INT          NOT NULL COMMENT '突破前境界（0=鍛體 … 8=渡劫）',
  `to_stage`             INT          NOT NULL COMMENT '突破後境界（1=練氣 … 9=飛昇）',
  `required_item_ids`    VARCHAR(255) NOT NULL DEFAULT '' COMMENT '消耗道具編號陣列（逗號分隔，空字串=不需要）',
  `protect_item_ids`     VARCHAR(255) NOT NULL DEFAULT '' COMMENT '護體道具編號陣列（逗號分隔，空字串=無護體選項）',
  `max_realm_level`      INT          NOT NULL DEFAULT 10 COMMENT '突破前需達到的境界最高等級',
  `base_success_rate`    INT          NOT NULL DEFAULT 100 COMMENT '基礎成功機率（0～100）',
  `increase_success_rate` INT         NOT NULL DEFAULT 0  COMMENT '持有護體道具時的額外成功機率加成（0～100）',
  PRIMARY KEY (`from_stage`),
  KEY `idx_to_stage` (`to_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界突破條件表';

INSERT INTO `breakthrough_requirement`
  (`from_stage`, `to_stage`, `required_item_ids`, `protect_item_ids`,
   `max_realm_level`, `base_success_rate`, `increase_success_rate`)
VALUES
  (0, 1, '40100', '',      10, 100,  0),  -- 鍛體→練氣：洗髓丹，必定成功
  (1, 2, '40101', '40102', 10,  70, 15),  -- 練氣→築基：築基丹 + 護脈散（護體+15%）
  (2, 3, '40103', '',      10,  60,  0),  -- 築基→金丹：降塵丹
  (3, 4, '40104', '40105', 10,  50, 15),  -- 金丹→元嬰：培嬰丹 + 定神香（護體+15%）
  (4, 5, '40106', '',      10,  45,  0),  -- 元嬰→化神：化神丹
  (5, 6, '40107', '',      10,  40,  0),  -- 化神→合體：太清玉液丹
  (6, 7, '40108', '',      10,  35,  0),  -- 合體→大乘：法則碎片
  (7, 8, '40109', '',      10,  30,  0),  -- 大乘→渡劫：天劫豁免令
  (8, 9, '40110', '',      10,  25,  0)   -- 渡劫→飛昇：登仙玉佩
ON DUPLICATE KEY UPDATE
  `required_item_ids`     = VALUES(`required_item_ids`),
  `protect_item_ids`      = VALUES(`protect_item_ids`),
  `max_realm_level`        = VALUES(`max_realm_level`),
  `base_success_rate`      = VALUES(`base_success_rate`),
  `increase_success_rate`  = VALUES(`increase_success_rate`);


-- ════════════════════════════════════════════════════════════
-- 7. 等級經驗值表
-- 固定 10 筆，PK 精確查詢已足夠
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `level_exp`;
CREATE TABLE `level_exp` (
  `level`   INT NOT NULL COMMENT '境界內等級（1 起算）',
  `exp_max` INT NOT NULL COMMENT '升至下一重所需總經驗值',
  PRIMARY KEY (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='各等級升級所需經驗值表';

INSERT INTO `level_exp` (`level`, `exp_max`) VALUES
  ( 1,   100),
  ( 2,   250),
  ( 3,   450),
  ( 4,   700),
  ( 5,  1000),
  ( 6,  1400),
  ( 7,  1900),
  ( 8,  2500),
  ( 9,  3200),
  (10,  4000)
ON DUPLICATE KEY UPDATE `exp_max` = VALUES(`exp_max`);


-- ════════════════════════════════════════════════════════════
-- 8. 道具表
-- 索引設計：
--   PK  item_id                  — 主要查詢（道具 ID 精確查詢）
--   IDX item_type                — 按類型篩選（如只查武器 / 防具 / 消耗品）
--   IDX name                     — 按名稱查詢（前綴索引 32 字元，策劃/GM 工具）
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `item`;
CREATE TABLE `item` (
  `item_id`              INT          NOT NULL COMMENT '道具編號',
  `name`                 VARCHAR(64)  NOT NULL COMMENT '道具名稱',
  `item_type`            TINYINT      NOT NULL DEFAULT 0  COMMENT '類型：0=一般道具 1=武器 2=防具',
  `stackable`            TINYINT(1)   NOT NULL DEFAULT 1  COMMENT '可疊加：1=是',
  `max_stack`            BIGINT       NOT NULL DEFAULT 1  COMMENT '最大疊加數量',
  `use_type`             TINYINT      NOT NULL DEFAULT 0  COMMENT '使用方式：0=不可使用 1=可直接使用',
  -- ── 武器屬性（item_type=1 時有效）──────────────────────
  `weapon_type`          TINYINT      NOT NULL DEFAULT 0  COMMENT '武器類型：0=無 1=劍 2=刀 3=槍…',
  `min_damage`           INT          NOT NULL DEFAULT 0  COMMENT '最小傷害',
  `max_damage`           INT          NOT NULL DEFAULT 0  COMMENT '最大傷害',
  `hit_modifier`         INT          NOT NULL DEFAULT 0  COMMENT '命中修正',
  -- ── 防具屬性（item_type=2 時有效）──────────────────────
  `armor_type`           TINYINT      NOT NULL DEFAULT 0  COMMENT '防具部位：0=無 1=頭 2=身 3=手 4=腳 5=盾',
  `ac`                   INT          NOT NULL DEFAULT 0  COMMENT '防禦值（Armor Class）',
  `damage_reduction`     INT          NOT NULL DEFAULT 0  COMMENT '傷害減免',
  -- ── 通用 ────────────────────────────────────────────────
  `material`             TINYINT      NOT NULL DEFAULT 0  COMMENT '材質',
  `note`                 VARCHAR(128) DEFAULT NULL        COMMENT '備註',
  PRIMARY KEY (`item_id`),
  KEY `idx_item_type` (`item_type`),
  KEY `idx_name`      (`name`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='道具定義表';

INSERT INTO `item`
  (`item_id`, `name`, `item_type`, `stackable`, `max_stack`, `use_type`,
   `weapon_type`, `min_damage`, `max_damage`, `hit_modifier`,
   `armor_type`, `ac`, `damage_reduction`, `material`, `note`)
VALUES
  -- ── 貨幣 / 通用消耗品 ──
  (40308, '金幣',       0, 1, 2000000000, 0, 0,  0,  0, 0, 0, 0, 0, 0, '通用貨幣'),
  (40010, '治癒藥水',   0, 1,       1000, 1, 0,  0,  0, 0, 0, 0, 0, 0, '恢復 HP'),
  -- ── 武器 ──
  (4,     '長劍',       1, 0,          1, 0, 1,  5, 12, 2, 0, 0, 0, 0, '單手劍'),
  -- ── 突破丹藥（境界 0→1 … 8→9）──
  (40100, '洗髓丹',     0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '鍛體→練氣突破用'),
  (40101, '築基丹',     0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '練氣→築基突破用'),
  (40102, '護脈散',     0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '練氣→築基護體'),
  (40103, '降塵丹',     0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '築基→金丹突破用'),
  (40104, '培嬰丹',     0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '金丹→元嬰突破用'),
  (40105, '定神香',     0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '金丹→元嬰護體'),
  (40106, '化神丹',     0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '元嬰→化神突破用'),
  (40107, '太清玉液丹', 0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '化神→合體突破用'),
  (40108, '法則碎片',   0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '合體→大乘突破用'),
  (40109, '天劫豁免令', 0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '大乘→渡劫突破用'),
  (40110, '登仙玉佩',   0, 1,        100, 1, 0,  0,  0, 0, 0, 0, 0, 0, '渡劫→飛昇突破用')
ON DUPLICATE KEY UPDATE
  `name`             = VALUES(`name`),
  `item_type`        = VALUES(`item_type`),
  `stackable`        = VALUES(`stackable`),
  `max_stack`        = VALUES(`max_stack`),
  `note`             = VALUES(`note`);


-- ════════════════════════════════════════════════════════════
-- 9. 地圖設定表
-- 索引設計：
--   PK  map_id                   — 精確查詢（MapTable.getMap / isValidCoord）
--   IDX safe_zone                — 安全區批次查詢（如：列出全部安全區地圖）
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `map`;
CREATE TABLE `map` (
  `map_id`      INT          NOT NULL COMMENT '地圖編號',
  `name`        VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '地圖顯示名稱',
  `min_x`       INT          NOT NULL DEFAULT 0    COMMENT 'X 座標最小值（邊界）',
  `max_x`       INT          NOT NULL DEFAULT 1000 COMMENT 'X 座標最大值（邊界）',
  `min_y`       INT          NOT NULL DEFAULT 0    COMMENT 'Y 座標最小值（邊界）',
  `max_y`       INT          NOT NULL DEFAULT 1000 COMMENT 'Y 座標最大值（邊界）',
  `safe_zone`   TINYINT(1)   NOT NULL DEFAULT 0    COMMENT '安全區：1=禁止攻擊',
  `pk_enabled`  TINYINT(1)   NOT NULL DEFAULT 0    COMMENT 'PK 開放：1=允許',
  `description` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '備註',
  PRIMARY KEY (`map_id`),
  KEY `idx_safe_zone` (`safe_zone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='地圖設定表';

INSERT INTO `map`
  (`map_id`, `name`, `min_x`, `max_x`, `min_y`, `max_y`, `safe_zone`, `pk_enabled`, `description`)
VALUES
  (0, '新手村',   0,  500, 0,  500, 1, 0, '出生點，安全區'),
  (1, '靈脈山谷', 0,  800, 0,  800, 0, 1, '初階修煉地帶'),
  (2, '青雲山',   0, 1200, 0, 1200, 0, 1, '中階修煉地帶'),
  (3, '天墟秘境', 0, 1000, 0, 1000, 0, 1, '高階副本入口')
ON DUPLICATE KEY UPDATE
  `name`        = VALUES(`name`),
  `min_x`       = VALUES(`min_x`), `max_x` = VALUES(`max_x`),
  `min_y`       = VALUES(`min_y`), `max_y` = VALUES(`max_y`),
  `safe_zone`   = VALUES(`safe_zone`),
  `pk_enabled`  = VALUES(`pk_enabled`),
  `description` = VALUES(`description`);


-- ════════════════════════════════════════════════════════════
-- 10. 傳送點表
-- 索引設計：
--   PK  portal_id (AUTO_INCREMENT) — 精確查詢（C_EnterPortal 驗證用）
--   IDX map_id                     — MapPortalTable.getPortalsByMap()：取得整張地圖的傳送點清單（小地圖顯示）
--   IDX dest_map_id                — 反向查詢：「哪些傳送點通往此地圖」（GM 工具 / 傳送網路管理用）
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `map_portal`;
CREATE TABLE `map_portal` (
  `portal_id`     INT         NOT NULL AUTO_INCREMENT COMMENT '傳送點編號',
  `map_id`        INT         NOT NULL COMMENT '所在地圖編號',
  `loc_x`         INT         NOT NULL DEFAULT 0 COMMENT '傳送點 X 座標（前端小地圖藍色光點）',
  `loc_y`         INT         NOT NULL DEFAULT 0 COMMENT '傳送點 Y 座標',
  `dest_map_id`   INT         NOT NULL COMMENT '目標地圖編號',
  `dest_x`        INT         NOT NULL DEFAULT 0 COMMENT '目標 X 座標',
  `dest_y`        INT         NOT NULL DEFAULT 0 COMMENT '目標 Y 座標',
  `trigger_range` INT         NOT NULL DEFAULT 3  COMMENT '觸發範圍（格數，Chebyshev 距離 ≤ 此值可使用）',
  `name`          VARCHAR(64) NOT NULL DEFAULT '' COMMENT '傳送點顯示名稱（如：前往青雲山）',
  PRIMARY KEY (`portal_id`),
  KEY `idx_map_id`      (`map_id`),
  KEY `idx_dest_map_id` (`dest_map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='地圖傳送點表';

INSERT INTO `map_portal`
  (`portal_id`, `map_id`, `loc_x`, `loc_y`, `dest_map_id`, `dest_x`, `dest_y`, `trigger_range`, `name`)
VALUES
  (1, 0,  450,  450, 1,   50,  50, 3, '前往靈脈山谷'),  -- 新手村 → 靈脈山谷
  (2, 1,   50,   50, 0,  450, 450, 3, '返回新手村'),    -- 靈脈山谷 → 新手村
  (3, 1,  750,  750, 2,   60,  60, 3, '前往青雲山'),    -- 靈脈山谷 → 青雲山
  (4, 2,   60,   60, 1,  750, 750, 3, '返回靈脈山谷'), -- 青雲山 → 靈脈山谷
  (5, 2, 1100,  900, 3,   50,  50, 3, '進入天墟秘境'),  -- 青雲山 → 天墟秘境
  (6, 3,   50,   50, 2, 1100, 900, 3, '返回青雲山')     -- 天墟秘境 → 青雲山
ON DUPLICATE KEY UPDATE
  `map_id`        = VALUES(`map_id`),
  `loc_x`         = VALUES(`loc_x`),     `loc_y`    = VALUES(`loc_y`),
  `dest_map_id`   = VALUES(`dest_map_id`),
  `dest_x`        = VALUES(`dest_x`),    `dest_y`   = VALUES(`dest_y`),
  `trigger_range` = VALUES(`trigger_range`),
  `name`          = VALUES(`name`);


-- ════════════════════════════════════════════════════════════
-- 11. 物件 ID 序列表
-- 索引設計：
--   PK  name                     — 精確查詢（目前只有 'obj_id' 一個序列）
-- 用途：
--   伺服器啟動時讀取 next_id 作為 IdFactory 起始值，
--   伺服器正常關閉時將當前最大已分配 ID 寫回此表，
--   避免重啟後重新掃描所有 entity 表才能確定下一號。
-- ════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS `id_sequence`;
CREATE TABLE `id_sequence` (
  `name`       VARCHAR(32)     NOT NULL COMMENT '序列名稱（如 obj_id）',
  `next_id`    BIGINT UNSIGNED NOT NULL DEFAULT 10000 COMMENT '下一個待分配的編號（關機時寫回）',
  `updated_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP COMMENT '最後更新時間',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物件 ID 序列持久化表';

INSERT INTO `id_sequence` (`name`, `next_id`) VALUES ('obj_id', 10000)
ON DUPLICATE KEY UPDATE `name` = `name`;


SET FOREIGN_KEY_CHECKS = 1;
