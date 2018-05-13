-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.09-MySQL.sql' to 'ShopDb::Schema v0.10':;

BEGIN;

ALTER TABLE `shopdb`.`material_lines` CHANGE COLUMN `unit_cost` `unit_cost` float;


COMMIT;

