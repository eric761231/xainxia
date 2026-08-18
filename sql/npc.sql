/*
 Navicat Premium Dump SQL

 Source Server         : localhost
 Source Server Type    : MySQL
 Source Server Version : 50541 (5.5.41)
 Source Host           : localhost:3306
 Source Schema         : xin_game

 Target Server Type    : MySQL
 Target Server Version : 50541 (5.5.41)
 File Encoding         : 65001

 Date: 15/08/2026 00:00:48
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for npc
-- ----------------------------
DROP TABLE IF EXISTS `npc`;
CREATE TABLE `npc`  (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '資料序號',
  `npc_id` int(10) UNSIGNED NULL DEFAULT NULL COMMENT 'npc編號',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '名稱註解',
  `type_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'npc類型分類代號',
  `gfxid` int(10) NULL DEFAULT 0 COMMENT '外型編號',
  `maxhp` int(10) NULL DEFAULT 0 COMMENT '最大體力',
  `maxmp` int(10) NULL DEFAULT 0 COMMENT '最大法力',
  `defense` int(10) NULL DEFAULT 0 COMMENT '防禦力',
  `base_damage` int(10) NULL DEFAULT 10 COMMENT '基礎傷害',
  `rand_damage` int(10) NULL DEFAULT 0 COMMENT '浮動傷害',
  `actionList` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '動作代號列表',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_bin ROW_FORMAT = Compact;

-- ----------------------------
-- Records of npc
-- ----------------------------

SET FOREIGN_KEY_CHECKS = 1;
