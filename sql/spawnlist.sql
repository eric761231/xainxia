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

 Date: 15/08/2026 00:01:00
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for spawnlist
-- ----------------------------
DROP TABLE IF EXISTS `spawnlist`;
CREATE TABLE `spawnlist`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '資料序號',
  `zone` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '地區註解',
  `npc_id` int(10) NOT NULL COMMENT 'npc編號',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin NULL DEFAULT NULL COMMENT 'npc名稱',
  `count` int(10) NOT NULL COMMENT 'npc數量',
  `locx` int(10) NOT NULL COMMENT '出生X座標',
  `locy` int(10) NOT NULL COMMENT '出生Y座標',
  `range` int(10) NOT NULL DEFAULT 5 COMMENT '出生範圍值',
  `mapid` int(10) NULL DEFAULT 0 COMMENT '地圖編號',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_bin ROW_FORMAT = Compact;

-- ----------------------------
-- Records of spawnlist
-- ----------------------------

SET FOREIGN_KEY_CHECKS = 1;
