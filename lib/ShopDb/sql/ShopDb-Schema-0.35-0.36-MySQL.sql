-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.35-MySQL.sql' to 'ShopDb::Schema v0.36':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`leave_types` (
  `leave_type_id` integer NOT NULL auto_increment,
  `label` varchar(32) NOT NULL,
  PRIMARY KEY (`leave_type_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`leaves` (
  `leave_id` integer NOT NULL auto_increment,
  `machinist_id` integer NOT NULL,
  `hours` float NOT NULL,
  `leave_type_id` integer NOT NULL,
  `date` date NOT NULL,
  INDEX `shopdb.leaves_idx_leave_type_id` (`leave_type_id`),
  INDEX `shopdb.leaves_idx_machinist_id` (`machinist_id`),
  PRIMARY KEY (`leave_id`),
  CONSTRAINT `shopdb.leaves_fk_leave_type_id` FOREIGN KEY (`leave_type_id`) REFERENCES `shopdb`.`leave_types` (`leave_type_id`),
  CONSTRAINT `shopdb.leaves_fk_machinist_id` FOREIGN KEY (`machinist_id`) REFERENCES `shopdb`.`machinists` (`machinist_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;


COMMIT;

