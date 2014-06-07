-- MySQL dump 10.13  Distrib 5.1.67, for debian-linux-gnu (i486)
--
-- Host: localhost    Database: migration_database
-- ------------------------------------------------------
-- Server version	5.1.67-0ubuntu0.10.04.1

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
-- Table structure for table `drug_map`
--

DROP TABLE IF EXISTS `drug_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `drug_map` (
  `drug_id` int(11) DEFAULT NULL,
  `bart_one_name` varchar(255) DEFAULT NULL,
  `bart2_two_name` varchar(255) DEFAULT NULL,
  `new_drug_id` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `drug_map`
--

LOCK TABLES `drug_map` WRITE;
/*!40000 ALTER TABLE `drug_map` DISABLE KEYS */;
INSERT INTO `drug_map` VALUES (2,'Stavudine 40 Lamivudine 150','Coviro40 (Lamivudine + Stavudine 150/40mg tablet)',91),(5,'Stavudine 30 Lamivudine 150 Nevirapine 200','d4T/3TC/NVP (30/150/200mg tablet)',613),(6,'Stavudine 40 Lamivudine 150 Nevirapine 200','Triomune-40',3),(7,'Efavirenz 600','EFV (Efavirenz 600mg tablet)',11),(8,'Zidovudine 300 Lamivudine 150','AZT/3TC (Zidovudine and Lamivudine 300/150mg)',39),(9,'Nevirapine 200','NVP (Nevirapine 200 mg tablet)',22),(10,'Abacavir 300','ABC (Abacavir 300mg tablet)',40),(11,'Didanosine 125','DDI (Didanosine 125mg tablet)',9),(12,'Lopinavir 133 Ritonavir 33','LPV/r (Lopinavir and Ritonavir 133/33mg tablet)',739),(13,'Didanosine 200','DDI (Didanosine 200mg tablet)',10),(14,'Tenofovir 300','TDF (Tenofavir 300 mg tablet)',14),(16,'Cotrimoxazole 480','Cotrimoxazole (480mg tablet)',297),(17,'Lopinavir 200 Ritonavir 50','LPV/r (Lopinavir and Ritonavir 200/50mg tablet)',73),(18,'Zidovudine Lamivudine Nevirapine','AZT/3TC/NVP',731),(20,'Zidovudine Lamivudine Tenofovir Lopinavir/ Ritonav','AZT/3TC/TDF/LPV/r',816),(21,'Didanosine Abacavir Lopinavir/Ritonavir','DDI/ABC/LPV/r',815),(22,'Lamivudine 150','3TC (Lamivudine 150mg tablet)',42),(27,'Zidovudine 300','AZT (Zidovudine 300mg tablet)',38),(29,'Stavudine 30','d4T (Stavudine 30mg tablet)',5),(50,'Stavudine 40','d4T (Stavudine 40mg tablet)',6),(51,'Efavirenz 200','EFV (Efavirenz 200mg tablet)',30),(56,'Stavudine 6 Lamivudine 30 Nevirapine 50','Triomune baby (d4T/3TC/NVP 6/30/50mg tablet)',72),(57,'Stavudine 6 Lamivudine 30','d4T/3TC (Stavudine Lamivudine 6/30mg tablet)',737),(59,'Zidovudine 300 Lamivudine 150 Nevirapine 200','AZT/3TC/NVP (300/150/200mg tablet)',731),(143,'Lopinavir 100 Ritonavir 25','LPV/r (Lopinavir and Ritonavir 100/25mg tablet)',74),(147,'Tenofovir 300mg Stavudine 300mg','TDF/d4T (Tenofavir and Stavudine 300/300mg tablet',814),(148,'Tenofovir Disoproxil Fumarate/Lamivudine 300mg/300','TDF/3TC (Tenofavir and Lamivudine 300/300mg tablet',734),(149,'Tenofavir 300 Lamivudine 300 and Efavirenz 600','TDF/3TC/EFV (300/300/600mg tablet)',735),(150,'Stavudine 30 Lamivudine 150','d4T/3TC (Stavudine Lamivudine 30/150 tablet)',738),(151,'Tenofavir 300 Lamivudine 300','TDF/3TC (Tenofavir and Lamivudine 300/300mg tablet',734),(152,'Zidovudine 60 Lamivudine 30','AZT/3TC (Zidovudine and Lamivudine 60/30 tablet)',736),(153,'Zidovudine 60 Lamivudine 30 Nevirapine 50','AZT/3TC/NVP (60/30/50mg tablet)',732), (155,'Lamivudine 60mg Stavudine 12mg Nevirapine 100mg','Triomune junior (d4T/3TC/NVP 12/60/100mg tablet)',813), (157,'INH or H (Isoniazid 100mg tablet)','INH or H (Isoniazid 100mg tablet)',24),(158,'Sulphadoxine 500mg / pryimethamine 25mg (sp)','Sulphadoxine and Pyrimenthane (25mg tablet)',205), (159,'Abacavir 60 and Lamivudine 30','ABC/3TC (Abacavir and Lamivudine 60/30mg tablet)',733),(160,'LPV/r (Lopinavir and Ritonavir syrup)','LPV/r (Lopinavir and Ritonavir syrup)',94), (161, 'Lamivudine 60mg Stavudine 12mg','d4T/3TC (Stavudine Lamivudine 6/30mg tablet)',737), (162, 'Cotrimoxazole 480mg','Cotrimoxazole (480mg tablet)',297),(163,'Didanosine 100','DDI (Didanosine 200mg tablet)',10),(164,'Atazanavir 300 mg/Ritonavir 100 mg','ATV/r (Atazanavir 300mg/Ritonavir 100mg)',932), (54, 'Fluconazole 200', 'Fluconazole (200mg tablet)', 26), (55,'Fluconazole 400', 'Fluconazole (400mg)',565 ),(NULL, 'Nelfinavir','NFV(Nelfinavir)', 951),(NULL, 'ATV/(Atazanavir)','ATV/(Atazanavir)', 952),(NULL, 'atypical mycobacteriosis treatment','atypical mycobacteriosis treatment', 953),(NULL, 'Lamivudine 300','Lamivudine 300', 957), (NULL, 'Stavudine Lamivudine Efavirenz','d4T/3TC/EFV (Stavudine Lamvudine Efavirenz)', 955), (NULL, 'insecticide treated net','insecticide treated net', 956), (NULL, 'Raltegravir 400mg', 'RAL (Raltegravir 400mg)',954), (NULL, 'Raltegravir 400 mg', 'RAL (Raltegravir 400mg)',954) , (NULL, 'Albendazole 200', 'Albendazole (200mg tablet)',106), (NULL, 'Amitriptylline 25', 'Amitriptyline (25mg tablets)',96), (NULL, 'Amoxicillin 250', 'Amoxicillin (250mg tablet)',112), (NULL, 'Aspirin 300', 'Aspirin (300mg tablet)',115), (NULL, 'Erythromycin 250', 'Erythromycin (250mg tablet)',160), (NULL, 'Ferrous Sulfate 205', 'Ferrous sulphate (1 tablet)',644), (NULL, 'Fluconazole 100', 'Fluconazole (200mg tablet)',26), (NULL, 'Ibuprofen 200', 'Ibuprofen (200mg tablet)',172), (NULL, 'Indomethacin 250', 'Indomethacin (50mg tablet)',651), (NULL, 'Magnesium Trisilicate 370', 'Magnesium Trisilicate (500mg)',587), (NULL, 'Metronidazole 200', 'Metronidazole 200mg tablet',376), (NULL, 'Nelfinavir 250', 'NFV(Nelfinavir)',951), (NULL, 'Oral Rehydration Salt', 'ORS (Oral Rehydration Salt 20g/dose)',191), (NULL, 'Paracetamol 500', 'Paracetamol (250mg)',818), (NULL, 'Phenobarbitone 30', 'Phenobarbitone (30mg tablet)',246), (NULL, 'Propranolol 40', 'Propranolol (40mg tablet)',560), (NULL, 'Quinine 300', 'Quinine Sulphate (300mg tablet)',772), (NULL, 'Salbutamol 4', 'Salbutamol (4mg tablet)',203), (NULL, 'Sulfadoxine Pyrimethamine 525', 'Sulphadoxine and Pyrimenthane (25mg tablet)',205), (NULL, 'Vincristine 1', 'Vincristine Sulphate (1mg PFR)',100), (NULL, 'Vitamin B Complex 25', 'Vitamin B complex (1 tablet)',329), (NULL, 'Unknown ARV drug', 'Unknown antiretroviral drug',0),(NULL, 'Stavudine Lamivudine Efavirenz', 'd4T/3TC/EFV (Stavudine Lamvudine Efavirenz)', 955),(NULL, 'Stavudine Lamivudine + Stavudine Lamivudine and Nevirapine', 'D4T+3TC/D4T+3TC+NVP', 730),(NULL, 'Stavudine Lamivudine Nevirapine (Triomune Junior)', 'Triomune junior (d4T/3TC/NVP 12/60/100mg tablet)', 813),(NULL, 'Stavudine Lamivudine Nevirapine (Triomune Baby)', 'Triomune baby (d4T/3TC/NVP 6/30/50mg tablet)', 72),(NULL, 'Stavudine Lamivudine Nevirapine', 'd4T/3TC/NVP (30/150/200mg tablet)', 613),(NULL, 'Tenofovir Lamivudine + Atazanavir and Ritonavir (ATV/r)', 'TDF/3TC + ALT/r', 933),(NULL, 'Zidovudine Lamivudine', 'AZT/3TC (Zidovudine and Lamivudine 300/150mg)', 39),(NULL, 'Zidovudine Lamivudine + Atazanavir and Ritonavir (ATV/r)', 'AZT/3TC + ALT/r', 934),(NULL, 'Zidovudine Lamivudine + Nevirapine','AZT/3TC/NVP', 731),(NULL, 'Zidovudine Lamivudine Tenofovir Lopinavir/ Ritonavir', 'AZT/3TC/TDF/LPV/r',816),(NULL, 'Zidovudine Lamivudine Nevirapine (fixed)', 'AZT/3TC/NVP', 731),(NULL, 'Zidovudine Lamivudine + Efavirenz', 'd4T/3TC/EFV (Stavudine Lamvudine Efavirenz)', 955),(NULL, 'Zidovudine Lamivudine + Zidovudine Lamivudine Nevirapine', 'Triomune junior (d4T/3TC/NVP 12/60/100mg tablet)', 813),(NULL, 'Zidovudine Lamivudine Lopinavir and Ritonavir', 'AZT/3TC/TDF/LPV/r', 816), (NULL, 'Cotrimoxazole 960', 'Cotrimoxazole (960mg)', 576), (NULL, 'Cotrimoxazole 1920', 'Cotrimoxazole (1920mg)', 576);
/*!40000 ALTER TABLE `drug_map` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-02-07 10:39:32
