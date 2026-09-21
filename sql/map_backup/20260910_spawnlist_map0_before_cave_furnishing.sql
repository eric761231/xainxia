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
-- Dumping data for table `spawnlist`
--
-- WHERE:  mapid=0

LOCK TABLES `spawnlist` WRITE;
/*!40000 ALTER TABLE `spawnlist` DISABLE KEYS */;
INSERT INTO `spawnlist` (`id`, `zone`, `obj_type`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`, `respawn_delay`) VALUES (16,'修練洞府','property',4001,'洞府書櫃',1,35,36,0,0,0);
INSERT INTO `spawnlist` (`id`, `zone`, `obj_type`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`, `respawn_delay`) VALUES (17,'修練洞府','property',4001,'洞府書櫃',1,47,36,0,0,0);
INSERT INTO `spawnlist` (`id`, `zone`, `obj_type`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`, `respawn_delay`) VALUES (18,'修練洞府','property',4003,'聚靈法陣',1,40,39,0,0,0);
INSERT INTO `spawnlist` (`id`, `zone`, `obj_type`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`, `respawn_delay`) VALUES (19,'修練洞府','property',4002,'洞府書桌',1,43,45,0,0,0);
INSERT INTO `spawnlist` (`id`, `zone`, `obj_type`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`, `respawn_delay`) VALUES (20,'修練洞府','property',4004,'紫藤盆栽',1,34,46,0,0,0);
INSERT INTO `spawnlist` (`id`, `zone`, `obj_type`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`, `respawn_delay`) VALUES (21,'修練洞府','property',4007,'翠竹盆栽',1,48,46,0,0,0);
INSERT INTO `spawnlist` (`id`, `zone`, `obj_type`, `npc_id`, `name`, `count`, `locx`, `locy`, `range`, `mapid`, `respawn_delay`) VALUES (22,'修練洞府','property',4008,'菊花盆景',1,35,48,0,0,0);
/*!40000 ALTER TABLE `spawnlist` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-10 23:20:37
