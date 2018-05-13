-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.13-MySQL.sql' to 'ShopDb::Schema v0.14':;

BEGIN;

ALTER TABLE `shopdb`.`material_lines` ADD COLUMN `unit` varchar(255) NOT NULL;


COMMIT;

