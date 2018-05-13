-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.42-MySQL.sql' to 'ShopDb::Schema v0.43':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `shopdb`.`sponsored_project_members` (
  `project_id` integer(16) NOT NULL,
  `team_member` varchar(31) NOT NULL,
  `proj_role` varchar(16) NOT NULL,
  INDEX (`project_id`),
  PRIMARY KEY (`project_id`),
  CONSTRAINT `shopdb.sponsored_project_members_fk_project_id` FOREIGN KEY (`project_id`) REFERENCES `shopdb`.`sponsored_projects` (`project_id`)
) ENGINE=InnoDB;

CREATE TABLE `shopdb`.`sponsored_projects` (
  `project_id` integer(11) NOT NULL,
  `descr` varchar(255) NOT NULL,
  `eff_status` varchar(1) NOT NULL,
  `business_unit` varchar(255) NOT NULL,
  PRIMARY KEY (`project_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;


COMMIT;

