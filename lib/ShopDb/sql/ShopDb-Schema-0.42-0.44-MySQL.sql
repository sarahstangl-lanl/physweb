-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.42-MySQL.sql' to 'ShopDb::Schema v0.44':;

BEGIN;

SET foreign_key_checks=0;

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

ALTER TABLE `shopdb`.`account_types` ADD COLUMN `internal` boolean(1) NOT NULL DEFAULT '1';

ALTER TABLE `shopdb`.`accounts` CHANGE COLUMN `account_type_id` `account_type_id` integer NOT NULL DEFAULT 1,
                                CHANGE COLUMN `fund_code` `fund_code` varchar(5) NULL,
                                CHANGE COLUMN `deptid` `deptid` varchar(10) NULL,
                                CHANGE COLUMN `program_code` `program_code` varchar(5) NULL,
                                CHANGE COLUMN `project_id` `project_id` varchar(15) NULL,
                                ADD INDEX `setid` (`setid`),
                                ADD INDEX `fund_code` (`fund_code`),
                                ADD INDEX `deptid` (`deptid`),
                                ADD INDEX `program_code` (`program_code`),
                                ADD INDEX `project_id` (`project_id`),
                                ADD INDEX `chartfield3` (`chartfield3`),
                                ADD INDEX `chartfield1` (`chartfield1`),
                                ADD INDEX `chartfield2` (`chartfield2`),
                                ADD UNIQUE `shopdb.accounts_setid_fund_code_deptid_program_code_pro_1d6e61ad` (`setid`, `fund_code`, `deptid`, `program_code`, `project_id`, `chartfield3`, `chartfield1`, `chartfield2`);

ALTER TABLE `shopdb`.`customers` CHANGE COLUMN `customer_type_id` `customer_type_id` integer NOT NULL DEFAULT 1;

ALTER TABLE `shopdb`.`labor_lines` CHANGE COLUMN `invoice_id` `invoice_id` varchar(30) NULL;

ALTER TABLE `shopdb`.`material_lines` CHANGE COLUMN `invoice_id` `invoice_id` varchar(30) NULL;


COMMIT;

