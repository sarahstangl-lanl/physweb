-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.06-MySQL.sql' to 'ShopDb::Schema v0.07':;

BEGIN;

ALTER TABLE `shopdb`.`labor_lines` ADD COLUMN `active` boolean NOT NULL DEFAULT '1';

ALTER TABLE `shopdb`.`material_lines` ADD COLUMN `active` boolean NOT NULL DEFAULT '1';


COMMIT;

