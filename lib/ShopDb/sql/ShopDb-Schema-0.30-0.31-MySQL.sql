-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.30-MySQL.sql' to 'ShopDb::Schema v0.31':;

BEGIN;

ALTER TABLE `shopdb`.`jobs` CHANGE COLUMN `quantity_ordered` `quantity_ordered` integer NOT NULL DEFAULT 1;


COMMIT;

