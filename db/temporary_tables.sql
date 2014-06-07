DROP TABLE IF EXISTS `temp_obs`;

CREATE TABLE  `temp_obs` (
  `obs_id` int(11) NOT NULL AUTO_INCREMENT,
  `person_id` int(11) NOT NULL,
  `concept_id` int(11) NOT NULL DEFAULT '0',
  `encounter_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `obs_datetime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `location_id` int(11) DEFAULT NULL,
  `obs_group_id` int(11) DEFAULT NULL,
  `accession_number` varchar(255) DEFAULT NULL,
  `value_group_id` int(11) DEFAULT NULL,
  `value_boolean` tinyint(1) DEFAULT NULL,
  `value_coded` int(11) DEFAULT NULL,
  `value_coded_name_id` int(11) DEFAULT NULL,
  `value_drug` int(11) DEFAULT NULL,
  `value_datetime` datetime DEFAULT NULL,
  `value_numeric` double DEFAULT NULL,
  `value_modifier` varchar(2) DEFAULT NULL,
  `value_text` text,
  `date_started` datetime DEFAULT NULL,
  `date_stopped` datetime DEFAULT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `voided` smallint(6) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `value_complex` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`obs_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1703 DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `temp_encounter`;

CREATE TABLE `temp_encounter` (
  `encounter_id` int(11) NOT NULL AUTO_INCREMENT,
  `encounter_type` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL DEFAULT '0',
  `provider_id` int(11) NOT NULL DEFAULT '0',
  `location_id` int(11) DEFAULT NULL,
  `form_id` int(11) DEFAULT NULL,
  `encounter_datetime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `voided` smallint(6) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  `changed_by` int(11) DEFAULT NULL,
  `date_changed` datetime DEFAULT NULL,
  PRIMARY KEY (`encounter_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1302965 DEFAULT CHARSET=utf8;
