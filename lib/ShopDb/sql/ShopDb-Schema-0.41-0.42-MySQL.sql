-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.41-MySQL.sql' to 'ShopDb::Schema v0.42':;

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
  `account_type_id` integer NOT NULL,
  `setid` varchar(9),
  `fund_code` decimal,
  `deptid` decimal,
  `program_code` decimal,
  `project_id` decimal,
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

SET foreign_key_checks=1;

ALTER TABLE `shopdb`.`customer_accounts` ADD INDEX `shopdb.customer_accounts_idx_account_key` (`account_key`),
                                         ADD CONSTRAINT `shopdb.customer_accounts_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);

ALTER TABLE `shopdb`.`invoices` ADD INDEX `shopdb.invoices_idx_account_key` (`account_key`),
                                ADD CONSTRAINT `shopdb.invoices_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);

ALTER TABLE `shopdb`.`jobs` ADD INDEX `shopdb.jobs_idx_account_key` (`account_key`),
                            ADD CONSTRAINT `shopdb.jobs_fk_account_key` FOREIGN KEY (`account_key`) REFERENCES `shopdb`.`accounts` (`account_key`);


COMMIT;

