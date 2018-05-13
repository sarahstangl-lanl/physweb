-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.33-MySQL.sql' to 'ShopDb::Schema v0.34':;

BEGIN;

ALTER TABLE `shopdb`.`packing_slips` CHANGE COLUMN `ship_address_id` `ship_address_id` integer;


COMMIT;

