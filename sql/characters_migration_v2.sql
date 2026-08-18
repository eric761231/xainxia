-- 既有 characters 表升級至 v2（靈根 attribute、本命法寶、四維、位置）
-- 執行前請備份資料庫；MySQL 5.7 請逐條執行並略過已存在欄位

-- 若欄位名為 gender，改為 sex：
-- ALTER TABLE `characters` CHANGE COLUMN `gender` `sex` TINYINT NOT NULL DEFAULT 0;

ALTER TABLE `characters`
  ADD COLUMN `attribute` TINYINT NOT NULL DEFAULT 0 COMMENT '靈根 0=金..6=雷' AFTER `sex`;

ALTER TABLE `characters`
  ADD COLUMN `natal_weapon_id` TINYINT NOT NULL DEFAULT 0 AFTER `attribute`;

ALTER TABLE `characters`
  ADD COLUMN `stats_intel` INT NOT NULL DEFAULT 10 AFTER `natal_weapon_id`;

ALTER TABLE `characters`
  ADD COLUMN `stats_spirit` INT NOT NULL DEFAULT 10 AFTER `stats_intel`;

ALTER TABLE `characters`
  ADD COLUMN `stats_agility` INT NOT NULL DEFAULT 10 AFTER `stats_spirit`;

ALTER TABLE `characters`
  ADD COLUMN `stats_constitution` INT NOT NULL DEFAULT 10 AFTER `stats_agility`;

ALTER TABLE `characters`
  ADD COLUMN `map_id` INT NOT NULL DEFAULT 0 AFTER `stats_constitution`;

ALTER TABLE `characters`
  ADD COLUMN `loc_x` INT NOT NULL DEFAULT 0 AFTER `map_id`;

ALTER TABLE `characters`
  ADD COLUMN `loc_y` INT NOT NULL DEFAULT 0 AFTER `loc_x`;

-- 若存在舊 class_id 欄位可選擇移除：
-- ALTER TABLE `characters` DROP COLUMN `class_id`;
