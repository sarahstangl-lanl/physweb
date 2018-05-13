-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.02-MySQL.sql' to 'ShopDb::Schema v0.03':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`audit_entries` (
  `entry_id` integer NOT NULL auto_increment,
  `directory_uid` integer NOT NULL,
  `result_type` varchar(255) NOT NULL,
  `result_id` integer NOT NULL,
  `action_type` varchar(255) NOT NULL,
  `value` text NOT NULL,
  `entry_date` datetime NOT NULL,
  PRIMARY KEY (`entry_id`)
);

SET foreign_key_checks=1;


COMMIT;

