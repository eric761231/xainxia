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

 Date: 14/08/2026 23:23:58
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for map
-- ----------------------------
DROP TABLE IF EXISTS `map`;
CREATE TABLE `map`  (
  `map_id` int(11) NOT NULL COMMENT '地圖編號',
  `name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '地圖顯示名稱',
  `min_x` int(11) NOT NULL DEFAULT 0 COMMENT 'X 座標最小值（邊界）',
  `max_x` int(11) NOT NULL DEFAULT 1000 COMMENT 'X 座標最大值（邊界）',
  `min_y` int(11) NOT NULL DEFAULT 0 COMMENT 'Y 座標最小值（邊界）',
  `max_y` int(11) NOT NULL DEFAULT 1000 COMMENT 'Y 座標最大值（邊界）',
  `safe_zone` tinyint(1) NOT NULL DEFAULT 0 COMMENT '安全區：1=禁止攻擊',
  `pk_enabled` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'PK 開放：1=允許',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '備註',
  PRIMARY KEY (`map_id`) USING BTREE,
  INDEX `idx_safe_zone`(`safe_zone`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '地圖設定表' ROW_FORMAT = Compact;

-- ----------------------------
-- Records of map
-- ----------------------------
INSERT INTO `map` VALUES (0, '修練洞府', 1, 50, 1, 50,1, 0, '出生房間');
INSERT INTO `map` VALUES (1, '黑森林', 1, 50, 1, 50,0, 0, '冒險地區1');
INSERT INTO `map` VALUES (2, '灰岩山', 1, 50, 1, 50,0, 0, '冒險地區2');
INSERT INTO `map` VALUES (3, '血獄島', 1, 50, 1, 50,0, 1, '冒險地區3');
INSERT INTO `map` VALUES (4, '雲雷峰', 1, 50, 1, 50,0, 1, '冒險地區4');
INSERT INTO `map` VALUES (5, '葬劍島', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (6, '斷魂海', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (7, '白骨嶺', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (8, '天墟山', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (9, '碧玉潭', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (10, '千月湖', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (11, '赤血海', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (12, '落霞峰', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (13, '九幽山', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (14, '風嘯原', 1, 50, 1, 50,0, 0, NULL);
INSERT INTO `map` VALUES (15, '青木原', 1, 50, 1, 50,0, 0, NULL);

SET FOREIGN_KEY_CHECKS = 1;
