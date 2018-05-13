-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.19-MySQL.sql' to 'ShopDb::Schema v0.20':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`packing_slips` (
  `packing_slip_id` integer NOT NULL auto_increment,
  `job_id` integer NOT NULL,
  `pdf` mediumblob NOT NULL,
  `ship_via` varchar(255) NOT NULL,
  `ship_reference` varchar(255) NOT NULL,
  `quantity_shipped` integer NOT NULL,
  `ship_date` date,
  `creator_uid` integer NOT NULL,
  INDEX `shopdb.packing_slips_idx_job_id` (`job_id`),
  PRIMARY KEY (`packing_slip_id`),
  CONSTRAINT `shopdb.packing_slips_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE `shopdb`.`jobs` DROP COLUMN `ship_date`,
                            DROP COLUMN `needs_shipping`,
                            ADD COLUMN `ship_method` varchar(255),
                            ADD COLUMN `quantity_ordered` integer,
                            ADD COLUMN `quantity_shipped` integer;


COMMIT;

