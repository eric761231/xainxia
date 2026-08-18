-- ============================================================
-- game_data_v2.sql — 境界突破條件表
-- 將原本 BreakthroughTemplate.java 中硬編碼的 REQUIREMENTS
-- 陣列移至資料庫，方便策劃調整各境界的丹藥需求與成功率。
-- ============================================================

CREATE TABLE IF NOT EXISTS `breakthrough_requirement` (
  `from_stage`         INT          NOT NULL COMMENT '突破前境界編號（對應 RealmTemplate 常數）',
  `to_stage`           INT          NOT NULL COMMENT '突破後境界編號',
  `required_item_name` VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '消耗丹藥名稱（空字串表示無需丹藥）',
  `protect_item_name`  VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '護體物品名稱（空字串表示無需護體）',
  `base_success_rate`  DOUBLE       NOT NULL DEFAULT 1.0 COMMENT '基礎成功率（0.0～1.0，1.0 = 必定成功）',
  PRIMARY KEY (`from_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='境界突破條件表';

-- ── 初始資料（對應境界：0鍛體 1練氣 2築基 3金丹 4元嬰 5化神 6合體 7大乘 8渡劫 9飛昇）──
INSERT INTO `breakthrough_requirement`
  (`from_stage`, `to_stage`, `required_item_name`, `protect_item_name`, `base_success_rate`)
VALUES
  (0, 1, '洗髓丹',   '',     1.00),   -- 鍛體 → 練氣：必定成功
  (1, 2, '築基丹',   '護脈散', 0.70), -- 練氣 → 築基
  (2, 3, '降塵丹',   '',     0.60),   -- 築基 → 金丹
  (3, 4, '培嬰丹',   '定神香', 0.50), -- 金丹 → 元嬰
  (4, 5, '化神丹',   '',     0.45),   -- 元嬰 → 化神
  (5, 6, '太清玉液丹', '',   0.40),   -- 化神 → 合體
  (6, 7, '法則碎片', '',     0.35),   -- 合體 → 大乘
  (7, 8, '天劫豁免令', '',   0.30),   -- 大乘 → 渡劫
  (8, 9, '登仙玉佩', '',     0.25);   -- 渡劫 → 飛昇
