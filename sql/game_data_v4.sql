-- ============================================================
-- game_data_v4.sql — 突破條件表重設計
-- 1. 補全剩餘突破丹藥道具至 item 表
-- 2. ALTER breakthrough_requirement：
--    - required_item_name / protect_item_name → 道具編號陣列（逗號分隔）
--    - base_success_rate DOUBLE → INT（0～100）
--    - 新增 increase_success_rate INT（護體物品加成機率）
--    - 新增 max_realm_level INT（突破前需達到的最高等級）
-- ============================================================

-- ── 步驟 1：補全突破丹藥道具 ────────────────────────────────────────────────
-- 40100 洗髓丹 / 40101 築基丹 / 40102 護脈散 已在 game_data.sql 中存在
-- 以下為補全其餘境界突破所需道具

INSERT IGNORE INTO `item`
  (`item_id`, `name`, `item_type`, `stackable`, `max_stack`, `use_type`,
   `weapon_type`, `min_damage`, `max_damage`, `hit_modifier`,
   `armor_type`, `ac`, `damage_reduction`, `material`, `description`)
VALUES
  (40103, '降塵丹',   0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '築基突破金丹用'),
  (40104, '培嬰丹',   0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '金丹突破元嬰用'),
  (40105, '定神香',   0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '金丹突破護體'),
  (40106, '化神丹',   0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '元嬰突破化神用'),
  (40107, '太清玉液丹', 0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '化神突破合體用'),
  (40108, '法則碎片', 0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '合體突破大乘用'),
  (40109, '天劫豁免令', 0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '大乘突破渡劫用'),
  (40110, '登仙玉佩', 0, 1, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, '渡劫突破飛昇用');

-- ── 步驟 2：ALTER breakthrough_requirement 欄位結構 ──────────────────────────
ALTER TABLE `breakthrough_requirement`
  DROP COLUMN  `required_item_name`,
  DROP COLUMN  `protect_item_name`,
  MODIFY COLUMN `base_success_rate` INT NOT NULL DEFAULT 100
    COMMENT '基礎突破成功機率（0～100）',
  ADD COLUMN `required_item_ids`     VARCHAR(255) NOT NULL DEFAULT ''
    COMMENT '消耗道具編號陣列（逗號分隔，空字串=不需要）'  AFTER `to_stage`,
  ADD COLUMN `protect_item_ids`      VARCHAR(255) NOT NULL DEFAULT ''
    COMMENT '護體道具編號陣列（逗號分隔，空字串=不需要）'  AFTER `required_item_ids`,
  ADD COLUMN `max_realm_level`       INT          NOT NULL DEFAULT 10
    COMMENT '突破前需達到的境界最高等級'                   AFTER `protect_item_ids`,
  ADD COLUMN `increase_success_rate` INT          NOT NULL DEFAULT 0
    COMMENT '持有護體道具時的額外成功機率加成（0～100）'   AFTER `base_success_rate`;

-- ── 步驟 3：更新 9 筆突破條件（道具 ID 陣列 + int 機率） ──────────────────────
UPDATE `breakthrough_requirement` SET
  required_item_ids = '40100', protect_item_ids = '',      max_realm_level = 10,
  base_success_rate = 100,     increase_success_rate = 0
WHERE from_stage = 0;  -- 鍛體 → 練氣：洗髓丹，必定成功

UPDATE `breakthrough_requirement` SET
  required_item_ids = '40101', protect_item_ids = '40102', max_realm_level = 10,
  base_success_rate = 70,      increase_success_rate = 15
WHERE from_stage = 1;  -- 練氣 → 築基：築基丹 + 護脈散（護體+15%）

UPDATE `breakthrough_requirement` SET
  required_item_ids = '40103', protect_item_ids = '',      max_realm_level = 10,
  base_success_rate = 60,      increase_success_rate = 0
WHERE from_stage = 2;  -- 築基 → 金丹：降塵丹

UPDATE `breakthrough_requirement` SET
  required_item_ids = '40104', protect_item_ids = '40105', max_realm_level = 10,
  base_success_rate = 50,      increase_success_rate = 15
WHERE from_stage = 3;  -- 金丹 → 元嬰：培嬰丹 + 定神香（護體+15%）

UPDATE `breakthrough_requirement` SET
  required_item_ids = '40106', protect_item_ids = '',      max_realm_level = 10,
  base_success_rate = 45,      increase_success_rate = 0
WHERE from_stage = 4;  -- 元嬰 → 化神：化神丹

UPDATE `breakthrough_requirement` SET
  required_item_ids = '40107', protect_item_ids = '',      max_realm_level = 10,
  base_success_rate = 40,      increase_success_rate = 0
WHERE from_stage = 5;  -- 化神 → 合體：太清玉液丹

UPDATE `breakthrough_requirement` SET
  required_item_ids = '40108', protect_item_ids = '',      max_realm_level = 10,
  base_success_rate = 35,      increase_success_rate = 0
WHERE from_stage = 6;  -- 合體 → 大乘：法則碎片

UPDATE `breakthrough_requirement` SET
  required_item_ids = '40109', protect_item_ids = '',      max_realm_level = 10,
  base_success_rate = 30,      increase_success_rate = 0
WHERE from_stage = 7;  -- 大乘 → 渡劫：天劫豁免令

UPDATE `breakthrough_requirement` SET
  required_item_ids = '40110', protect_item_ids = '',      max_realm_level = 10,
  base_success_rate = 25,      increase_success_rate = 0
WHERE from_stage = 8;  -- 渡劫 → 飛昇：登仙玉佩
