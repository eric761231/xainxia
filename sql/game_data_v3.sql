-- ============================================================
-- game_data_v3.sql — 等級經驗表 & 境界定義表
-- 將原本硬編碼在 LevelExpTemplate / RealmTemplate 的遊戲數值
-- 移至資料庫，方便策劃調整非線性經驗曲線與境界名稱。
-- ============================================================

-- ── 各等級升級所需經驗值 ──────────────────────────────────────
-- level 對應境界內小等級（1 = 第 1 重，依序到 levels_per_realm）
CREATE TABLE IF NOT EXISTS `level_exp` (
  `level`   INT NOT NULL COMMENT '境界內等級（1 起算）',
  `exp_max` INT NOT NULL COMMENT '升至下一重所需總經驗值',
  PRIMARY KEY (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='各等級升級所需經驗值';

INSERT INTO `level_exp` (`level`, `exp_max`) VALUES
  (1,  100),
  (2,  200),
  (3,  300),
  (4,  400),
  (5,  500),
  (6,  600),
  (7,  700),
  (8,  800),
  (9,  900),
  (10, 1000);

-- ── 境界定義表 ────────────────────────────────────────────────
-- stage 對應 RealmTemplate 中的境界常數（0=鍛體 … 9=飛昇）
-- levels_per_realm 各境界目前統一為 10，可依需要獨立調整
CREATE TABLE IF NOT EXISTS `realm_definition` (
  `stage`            INT         NOT NULL COMMENT '境界編號（0=鍛體 … 9=飛昇）',
  `name`             VARCHAR(16) NOT NULL COMMENT '境界名稱（顯示用）',
  `levels_per_realm` INT         NOT NULL DEFAULT 10 COMMENT '此境界的小等級上限（達到才可嘗試突破）',
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
  (9, '飛升期', 10);
