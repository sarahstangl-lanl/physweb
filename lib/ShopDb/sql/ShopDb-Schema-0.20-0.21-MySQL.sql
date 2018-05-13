-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.20-MySQL.sql' to 'ShopDb::Schema v0.21':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`job_statuses` (
  `job_status_id` integer NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY (`job_status_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE `shopdb`.`jobs` DROP COLUMN `status`,
                            ADD COLUMN `job_status_id` integer NOT NULL,
                            ADD INDEX `shopdb.jobs_idx_job_status_id` (`job_status_id`),
                            ADD CONSTRAINT `shopdb.jobs_fk_job_status_id` FOREIGN KEY (`job_status_id`) REFERENCES `shopdb`.`job_statuses` (`job_status_id`);


COMMIT;

