-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.10-MySQL.sql' to 'ShopDb::Schema v0.11':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`invoices` (
  `invoice_id` integer NOT NULL auto_increment,
  `job_id` integer NOT NULL,
  `pdf` mediumblob NOT NULL,
  `bill_date` date,
  `paid_date` date,
  `creation_date` date NOT NULL,
  `creator_uid` integer NOT NULL,
  `account_key` varchar(255) NOT NULL,
  INDEX `shopdb.invoices_idx_job_id` (`job_id`),
  PRIMARY KEY (`invoice_id`),
  CONSTRAINT `shopdb.invoices_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE `shopdb`.`labor_lines` ADD COLUMN `invoice_id` integer,
                                   ADD INDEX `shopdb.labor_lines_idx_invoice_id` (`invoice_id`),
                                   ADD CONSTRAINT `shopdb.labor_lines_fk_invoice_id` FOREIGN KEY (`invoice_id`) REFERENCES `shopdb`.`invoices` (`invoice_id`);

ALTER TABLE `shopdb`.`material_lines` ADD COLUMN `invoice_id` integer,
                                      ADD INDEX `shopdb.material_lines_idx_invoice_id` (`invoice_id`),
                                      ADD CONSTRAINT `shopdb.material_lines_fk_invoice_id` FOREIGN KEY (`invoice_id`) REFERENCES `shopdb`.`invoices` (`invoice_id`);


COMMIT;

