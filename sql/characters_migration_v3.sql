-- 既有 characters 表升級至 v3（HP/MP、防禦力、經驗值、境界、勢力、生活職業、核心功法）
-- 執行前請備份資料庫；MySQL 5.7 請逐條執行並略過已存在欄位

ALTER TABLE `characters`
  ADD COLUMN `current_hp` INT NOT NULL DEFAULT 0 AFTER `loc_y`;

ALTER TABLE `characters`
  ADD COLUMN `max_hp` INT NOT NULL DEFAULT 0 AFTER `current_hp`;

ALTER TABLE `characters`
  ADD COLUMN `current_mp` INT NOT NULL DEFAULT 0 AFTER `max_hp`;

ALTER TABLE `characters`
  ADD COLUMN `max_mp` INT NOT NULL DEFAULT 0 AFTER `current_mp`;

ALTER TABLE `characters`
  ADD COLUMN `defense` INT NOT NULL DEFAULT 0 AFTER `max_mp`;

ALTER TABLE `characters`
  ADD COLUMN `exp` INT NOT NULL DEFAULT 0 AFTER `defense`;

ALTER TABLE `characters`
  ADD COLUMN `realm_stage` TINYINT NOT NULL DEFAULT 0 COMMENT '境界階段，0=練氣期' AFTER `exp`;

ALTER TABLE `characters`
  ADD COLUMN `faction` VARCHAR(24) NOT NULL DEFAULT '' COMMENT '勢力' AFTER `realm_stage`;

ALTER TABLE `characters`
  ADD COLUMN `life_job` VARCHAR(24) NOT NULL DEFAULT '' COMMENT '生活職業' AFTER `faction`;

ALTER TABLE `characters`
  ADD COLUMN `life_job_level` INT NOT NULL DEFAULT 0 AFTER `life_job`;

ALTER TABLE `characters`
  ADD COLUMN `core_technique` VARCHAR(24) NOT NULL DEFAULT '' COMMENT '核心功法' AFTER `life_job_level`;
