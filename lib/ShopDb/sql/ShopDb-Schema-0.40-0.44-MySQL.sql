-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.40-MySQL.sql' to 'ShopDb::Schema v0.44':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`account_types` (
  `account_type_id` integer NOT NULL auto_increment,
  `internal` enum('0','1') NOT NULL DEFAULT '1',
  `label` varchar(255) NOT NULL,
  `sort_order` integer NOT NULL DEFAULT 0,
  PRIMARY KEY (`account_type_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`accounts` (
  `account_key` varchar(255) NOT NULL,
  `account_type_id` integer NOT NULL DEFAULT 1,
  `setid` varchar(9) NULL,
  `fund_code` varchar(5) NULL,
  `deptid` varchar(10) NULL,
  `program_code` varchar(5) NULL,
  `project_id` varchar(15) NULL,
  `chartfield3` varchar(10) NULL,
  `chartfield1` varchar(10) NULL,
  `chartfield2` varchar(10) NULL,
  `descr50` varchar(50) NULL,
  `lastupddttm` date NULL,
  `lastupdoprid` varchar(10) NULL,
  `auto-added` enum('0','1') NOT NULL DEFAULT '0',
  `disabled` enum('0','1') NOT NULL DEFAULT '0',
  `comment` text NULL,
  INDEX `shopdb.accounts_idx_account_type_id` (`account_type_id`),
  INDEX `setid` (`setid`),
  INDEX `fund_code` (`fund_code`),
  INDEX `deptid` (`deptid`),
  INDEX `program_code` (`program_code`),
  INDEX `project_id` (`project_id`),
  INDEX `chartfield3` (`chartfield3`),
  INDEX `chartfield1` (`chartfield1`),
  INDEX `chartfield2` (`chartfield2`),
  PRIMARY KEY (`account_key`),
  UNIQUE `shopdb.accounts_setid_fund_code_deptid_program_code_pro_1d6e61ad` (`setid`, `fund_code`, `deptid`, `program_code`, `project_id`, `chartfield3`, `chartfield1`, `chartfield2`),
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

ALTER TABLE `shopdb`.`customer_accounts` ADD INDEX `shopdb.customer_accounts_idx_account_key` (`account_key`),
                                         ADD CONSTRAINT `shopdb.customer_accounts_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);

ALTER TABLE `shopdb`.`customers` ADD COLUMN `customer_type_id` integer NOT NULL DEFAULT 1,
                                 ADD INDEX `shopdb.customers_idx_customer_type_id` (`customer_type_id`),
                                 ADD CONSTRAINT `shopdb.customers_fk_customer_type_id` FOREIGN KEY (`customer_type_id`) REFERENCES `shopdb`.`customer_types` (`customer_type_id`);

ALTER TABLE `shopdb`.`invoices` ADD INDEX `shopdb.invoices_idx_account_key` (`account_key`),
                                ADD CONSTRAINT `shopdb.invoices_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);

ALTER TABLE `shopdb`.`jobs` ADD INDEX `shopdb.jobs_idx_account_key` (`account_key`),
                            ADD CONSTRAINT `shopdb.jobs_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);

ALTER TABLE `shopdb`.`labor_lines` CHANGE COLUMN `invoice_id` `invoice_id` varchar(30) NULL;

ALTER TABLE `shopdb`.`material_lines` CHANGE COLUMN `invoice_id` `invoice_id` varchar(30) NULL;


COMMIT;

