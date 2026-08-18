-- 既有 characters 表升級至 v4（level 欄位改名為 realm_level，語意為境界內小等級 1~10）
-- 執行前請備份資料庫；MySQL 5.7 請逐條執行並略過已存在欄位

ALTER TABLE `characters`
  CHANGE COLUMN `level` `realm_level` INT NOT NULL DEFAULT 1 COMMENT '境界內小等級 1~10';
