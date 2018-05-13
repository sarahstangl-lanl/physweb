-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.15-MySQL.sql' to 'ShopDb::Schema v0.16':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`estimate_labor_lines` (
  `estimate_labor_line_id` integer NOT NULL auto_increment,
  `job_estimate_id` integer NOT NULL,
  `task` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `charge_hours` float NOT NULL DEFAULT 0,
  INDEX `shopdb.estimate_labor_lines_idx_job_estimate_id` (`job_estimate_id`),
  PRIMARY KEY (`estimate_labor_line_id`),
  CONSTRAINT `shopdb.estimate_labor_lines_fk_job_estimate_id` FOREIGN KEY (`job_estimate_id`) REFERENCES `shopdb`.`job_estimates` (`job_estimate_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`estimate_material_lines` (
  `estimate_material_line_id` integer NOT NULL auto_increment,
  `job_estimate_id` integer NOT NULL,
  `quantity` integer NOT NULL,
  `unit` varchar(255) NOT NULL,
  `unit_cost` float,
  `type` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  INDEX `shopdb.estimate_material_lines_idx_job_estimate_id` (`job_estimate_id`),
  PRIMARY KEY (`estimate_material_line_id`),
  CONSTRAINT `shopdb.estimate_material_lines_fk_job_estimate_id` FOREIGN KEY (`job_estimate_id`) REFERENCES `shopdb`.`job_estimates` (`job_estimate_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`job_estimates` (
  `job_estimate_id` integer NOT NULL auto_increment,
  `job_id` integer NOT NULL,
  `creator_uid` integer NOT NULL,
  `created_date` date NOT NULL,
  INDEX `shopdb.job_estimates_idx_job_id` (`job_id`),
  PRIMARY KEY (`job_estimate_id`),
  CONSTRAINT `shopdb.job_estimates_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;


COMMIT;

