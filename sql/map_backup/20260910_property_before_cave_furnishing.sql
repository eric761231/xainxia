-- MySQL dump 10.13  Distrib 5.5.41, for Win32 (x86)
--
-- Host: localhost    Database: xin_game
-- ------------------------------------------------------
-- Server version	5.5.41

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `property`
--

LOCK TABLES `property` WRITE;
/*!40000 ALTER TABLE `property` DISABLE KEYS */;
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (1200,1200,1,2,3,0,1,'floor','木桌一',0,0,0,'');
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (1201,1201,1,3,2,0,1,'floor','木桌二',0,0,0,'');
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (4001,4001,1,2,2,0,0,'floor','洞府書櫃',0,0,0,'');
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (4002,4002,1,3,2,0,0,'floor','洞府書桌',0,0,0,'');
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (4003,4003,0,3,3,0,0,'floor','聚靈法陣',0,0,0,'');
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (4004,4004,1,1,1,0,0,'floor','紫藤盆栽',0,0,0,'');
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (4007,4007,1,1,1,0,0,'floor','翠竹盆栽',0,0,0,'');
INSERT INTO `property` (`id`, `pngid`, `blocking`, `footprint_w`, `footprint_h`, `min_gap`, `placeable`, `placement`, `view_note`, `action`, `action_type`, `value`, `bubble_text`) VALUES (4008,4008,1,1,1,0,0,'floor','菊花盆景',0,0,0,'');
/*!40000 ALTER TABLE `property` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-10 23:20:35
