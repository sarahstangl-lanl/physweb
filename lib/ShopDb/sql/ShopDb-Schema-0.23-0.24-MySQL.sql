-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.23-MySQL.sql' to 'ShopDb::Schema v0.24':;

BEGIN;

ALTER TABLE `shopdb`.`packing_slips` ADD COLUMN `quantity_backordered` integer NOT NULL;


COMMIT;

