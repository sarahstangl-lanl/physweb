-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.16-MySQL.sql' to 'ShopDb::Schema v0.17':;

BEGIN;

ALTER TABLE `shopdb`.`estimate_material_lines` ADD COLUMN `subtype` varchar(255) NOT NULL;


COMMIT;

