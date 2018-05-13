-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.38-MySQL.sql' to 'ShopDb::Schema v0.39':;

BEGIN;

ALTER TABLE `shopdb`.`material_lines` CHANGE COLUMN `quantity` `quantity` float NOT NULL;


COMMIT;

