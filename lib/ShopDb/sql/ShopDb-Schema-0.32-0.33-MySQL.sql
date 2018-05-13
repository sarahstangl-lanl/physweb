-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.32-MySQL.sql' to 'ShopDb::Schema v0.33':;

BEGIN;

ALTER TABLE `shopdb`.`packing_slip_lines` ADD COLUMN `quantity_backordered` integer NOT NULL;


COMMIT;

