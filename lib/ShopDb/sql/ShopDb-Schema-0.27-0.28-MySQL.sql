-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.27-MySQL.sql' to 'ShopDb::Schema v0.28':;

BEGIN;

ALTER TABLE `shopdb`.`customers` ADD COLUMN `title` varchar(255),
                                 ADD COLUMN `comments` varchar(1024),
                                 CHANGE COLUMN `company_name` `company_name` varchar(1024);

ALTER TABLE `shopdb`.`labor_lines` DROP COLUMN `override_cost`;

ALTER TABLE `shopdb`.`material_lines` DROP COLUMN `override_cost`;


COMMIT;

