-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.40-MySQL.sql' to 'ShopDb::Schema v0.43':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`account_types` (
  `account_type_id` integer NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  `sort_order` integer NOT NULL DEFAULT 0,
  PRIMARY KEY (`account_type_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`accounts` (
  `account_key` varchar(255) NOT NULL,
  `account_type_id` integer NOT NULL DEFAULT 1,
  `setid` varchar(9),
  `fund_code` varchar(5),
  `deptid` varchar(10),
  `program_code` varchar(5),
  `project_id` varchar(15),
  `chartfield3` varchar(10),
  `chartfield1` varchar(10),
  `chartfield2` varchar(10),
  `descr50` varchar(50),
  `lastupddttm` date,
  `lastupdoprid` varchar(10),
  `auto-added` enum('0','1') NOT NULL DEFAULT '0',
  `disabled` enum('0','1') NOT NULL DEFAULT '0',
  `comment` text,
  INDEX `shopdb.accounts_idx_account_type_id` (`account_type_id`),
  PRIMARY KEY (`account_key`),
  CONSTRAINT `shopdb.accounts_fk_account_type_id` FOREIGN KEY (`account_type_id`) REFERENCES `shopdb`.`account_types` (`account_type_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`customer_types` (
  `customer_type_id` integer NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  `sort_order` integer NOT NULL DEFAULT 0,
  PRIMARY KEY (`customer_type_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`sponsored_project_members` (
  `project_id` varchar(15) NOT NULL,
  `team_member` varchar(31) NOT NULL,
  `proj_role` varchar(16) NOT NULL,
  INDEX `shopdb.sponsored_project_members_idx_project_id` (`project_id`),
  PRIMARY KEY (`project_id`, `team_member`),
  CONSTRAINT `shopdb.sponsored_project_members_fk_project_id` FOREIGN KEY (`project_id`) REFERENCES `shopdb`.`sponsored_projects` (`project_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`sponsored_projects` (
  `project_id` varchar(15) NOT NULL,
  `descr` varchar(255) NOT NULL,
  `eff_status` varchar(1) NOT NULL,
  `business_unit` varchar(5) NOT NULL,
  PRIMARY KEY (`project_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

INSERT INTO `shopdb`.`account_types` VALUES (NULL, 'Internal', 0);

INSERT INTO `shopdb`.`accounts` (`ACCOUNT_KEY`, `SETID`, `FUND_CODE`, `DEPTID`, `PROGRAM_CODE`, `PROJECT_ID`, `CHARTFIELD3`, `CHARTFIELD1`, `CHARTFIELD2`, `DESCR50`, `LASTUPDDTTM`, `LASTUPDOPRID`, `auto-added`, `disabled`, `comment`) SELECT `ACCOUNT_KEY`, `SETID`, `FUND_CODE`, `DEPTID`, `PROGRAM_CODE`, `PROJECT_ID`, `CHARTFIELD3`, `CHARTFIELD1`, `CHARTFIELD2`, `DESCR50`, `LASTUPDDTTM`, `LASTUPDOPRID`, `auto-added`, `disabled`, `comment` FROM `webdb`.`efs_accounts`;

DELETE `shopdb`.`customer_accounts` FROM `shopdb`.`customer_accounts` LEFT JOIN `shopdb`.`accounts` ON `shopdb`.`customer_accounts`.`account_key` = `shopdb`.`accounts`.`account_key` WHERE `shopdb`.`accounts`.`account_key` IS NULL;

ALTER TABLE `shopdb`.`customer_accounts` ADD INDEX `shopdb.customer_accounts_idx_account_key` (`account_key`),
                                         ADD CONSTRAINT `shopdb.customer_accounts_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);

INSERT INTO `shopdb`.`customer_types` VALUES (NULL, 'Internal', 0);

ALTER TABLE `shopdb`.`customers` ADD COLUMN `customer_type_id` integer NOT NULL DEFAULT 1,
                                 ADD INDEX `shopdb.customers_idx_customer_type_id` (`customer_type_id`),
                                 ADD CONSTRAINT `shopdb.customers_fk_customer_type_id` FOREIGN KEY (`customer_type_id`) REFERENCES `shopdb`.`customer_types` (`customer_type_id`);

ALTER TABLE `shopdb`.`invoices` ADD INDEX `shopdb.invoices_idx_account_key` (`account_key`),
                                ADD CONSTRAINT `shopdb.invoices_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);

CREATE TEMPORARY TABLE `shopdb`.`jobs_tmp` SELECT `shopdb`.`jobs`.`job_id` FROM `shopdb`.`jobs` LEFT JOIN `shopdb`.`accounts` ON `shopdb`.`jobs`.`account_key` = `shopdb`.`accounts`.`account_key` WHERE `shopdb`.`jobs`.`account_key` IS NOT NULL AND `shopdb`.`accounts`.`account_key` IS NULL;

UPDATE `shopdb`.`jobs` SET `shopdb`.`jobs`.`account_key` = NULL WHERE `shopdb`.`jobs`.`job_id` IN (SELECT * FROM `shopdb`.`jobs_tmp`);

ALTER TABLE `shopdb`.`jobs` ADD INDEX `shopdb.jobs_idx_account_key` (`account_key`),
                            ADD CONSTRAINT `shopdb.jobs_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);

--DROP TABLE `webdb`.`efs_accounts`, `webdb`.`efs_projects`, `webdb`.`efs_project_members`;

COMMIT;

