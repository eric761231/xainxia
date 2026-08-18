-- 角色表新增衍生戰鬥屬性欄位
ALTER TABLE `characters`
  ADD COLUMN `attack` INT NOT NULL DEFAULT 0 AFTER `defense`,
  ADD COLUMN `hit` INT NOT NULL DEFAULT 0 AFTER `attack`,
  ADD COLUMN `dodge` INT NOT NULL DEFAULT 0 AFTER `hit`,
  ADD COLUMN `hp_regen` INT NOT NULL DEFAULT 0 AFTER `dodge`,
  ADD COLUMN `mp_regen` INT NOT NULL DEFAULT 0 AFTER `hp_regen`,
  ADD COLUMN `puppet_max` INT NOT NULL DEFAULT 0 AFTER `mp_regen`,
  ADD COLUMN `spell_learn_rate` INT NOT NULL DEFAULT 100 AFTER `puppet_max`,
  ADD COLUMN `craft_proficiency_rate` INT NOT NULL DEFAULT 100 AFTER `spell_learn_rate`;
