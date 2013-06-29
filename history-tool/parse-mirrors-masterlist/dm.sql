-- MySQL dump 10.11
--
-- Host: localhost    Database: debian_mirror
-- ------------------------------------------------------
-- Server version	5.0.77-1-log

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
-- Table structure for table `surrogates`
--

DROP TABLE IF EXISTS `surrogates`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `surrogates` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `site` text NOT NULL,
  `site_type` text,
  `site_ipaddr` text,
  `site_bps` text,

  `country` text,
  `c3` text,
  `continent` text,

  `ipv6` text,
  `site_alias` text,
  `includes` text,
  `archive_architecture` text,
  `archive_http` text,
  `archive_ftp` text,
  `archive_upstream` text,
  `archive_rsync` text,

  `volatile_architecture` text,
  `volatile_http` text,
  `volatile_ftp` text,
  `volatile_upstream` text,
  `volatile_rsync` text,

  `ctld` text,
  `cdn_capable` text,
  `cdn_volatile_capable` text,
  `cdn_capability` int(10),
  `parent_id` int(10),
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=420 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `surrogates`
--

LOCK TABLES `surrogates` WRITE;
/*!40000 ALTER TABLE `surrogates` DISABLE KEYS */;
/*!40000 ALTER TABLE `surrogates` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-04-10 15:46:45
