-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.40-MySQL.sql' to 'ShopDb::Schema v0.41':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`customer_types` (
  `customer_type_id` integer NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  `sort_order` integer NOT NULL DEFAULT 0,
  PRIMARY KEY (`customer_type_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE `shopdb`.`customers` ADD COLUMN `customer_type_id` integer,
                                 ADD INDEX `shopdb.customers_idx_customer_type_id` (`customer_type_id`),
                                 ADD CONSTRAINT `shopdb.customers_fk_customer_type_id` FOREIGN KEY (`customer_type_id`) REFERENCES `shopdb`.`customer_types` (`customer_type_id`);


COMMIT;

