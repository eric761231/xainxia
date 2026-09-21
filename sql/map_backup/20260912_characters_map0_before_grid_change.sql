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
-- Dumping data for table `characters`
--
-- WHERE:  map_id=0

LOCK TABLES `characters` WRITE;
/*!40000 ALTER TABLE `characters` DISABLE KEYS */;
INSERT INTO `characters` (`account_name`, `obj_id`, `char_name`, `sex`, `attribute`, `natal_weapon_id`, `stats_intel`, `stats_spirit`, `stats_agility`, `stats_constitution`, `map_id`, `loc_x`, `loc_y`, `current_hp`, `max_hp`, `current_mp`, `max_mp`, `defense`, `attack`, `hit`, `dodge`, `hp_regen`, `mp_regen`, `puppet_max`, `spell_learn_rate`, `craft_proficiency_rate`, `exp`, `realm_stage`, `realm_level`, `faction`, `life_job`, `life_job_level`, `core_technique`) VALUES ('eric',10002,'月蒼海',0,0,0,14,14,10,10,0,40,40,119,205,193,193,26,5,30,25,11,15,4,128,128,56,0,2,'','',0,'');
INSERT INTO `characters` (`account_name`, `obj_id`, `char_name`, `sex`, `attribute`, `natal_weapon_id`, `stats_intel`, `stats_spirit`, `stats_agility`, `stats_constitution`, `map_id`, `loc_x`, `loc_y`, `current_hp`, `max_hp`, `current_mp`, `max_mp`, `defense`, `attack`, `hit`, `dodge`, `hp_regen`, `mp_regen`, `puppet_max`, `spell_learn_rate`, `craft_proficiency_rate`, `exp`, `realm_stage`, `realm_level`, `faction`, `life_job`, `life_job_level`, `core_technique`) VALUES ('eric',10003,'芸非',1,6,0,13,14,10,11,0,43,42,210,210,190,190,27,5,30,25,12,15,4,126,126,0,0,1,'','',0,'');
INSERT INTO `characters` (`account_name`, `obj_id`, `char_name`, `sex`, `attribute`, `natal_weapon_id`, `stats_intel`, `stats_spirit`, `stats_agility`, `stats_constitution`, `map_id`, `loc_x`, `loc_y`, `current_hp`, `max_hp`, `current_mp`, `max_mp`, `defense`, `attack`, `hit`, `dodge`, `hp_regen`, `mp_regen`, `puppet_max`, `spell_learn_rate`, `craft_proficiency_rate`, `exp`, `realm_stage`, `realm_level`, `faction`, `life_job`, `life_job_level`, `core_technique`) VALUES ('tester2',10099,'洛清塵',0,0,0,14,14,10,10,0,40,40,210,210,196,196,27,7,30,25,11,15,4,128,128,195,0,3,'','',0,'');
/*!40000 ALTER TABLE `characters` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-12 23:57:24
