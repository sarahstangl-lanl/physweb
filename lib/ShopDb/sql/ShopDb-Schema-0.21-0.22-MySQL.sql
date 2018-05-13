-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.21-MySQL.sql' to 'ShopDb::Schema v0.22':;

BEGIN;

ALTER TABLE `shopdb`.`packing_slips` CHANGE COLUMN `ship_reference` `ship_reference` varchar(255);


COMMIT;

