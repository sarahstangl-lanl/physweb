-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.22-MySQL.sql' to 'ShopDb::Schema v0.23':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`packing_slip_lines` (
  `packing_slip_line_id` integer NOT NULL auto_increment,
  `packing_slip_id` integer NOT NULL,
  `description` text NOT NULL,
  `quantity_backordered` integer NOT NULL,
  `quantity_shipped` integer NOT NULL,
  INDEX `shopdb.packing_slip_lines_idx_packing_slip_id` (`packing_slip_id`),
  PRIMARY KEY (`packing_slip_line_id`),
  CONSTRAINT `shopdb.packing_slip_lines_fk_packing_slip_id` FOREIGN KEY (`packing_slip_id`) REFERENCES `shopdb`.`packing_slips` (`packing_slip_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;


COMMIT;

