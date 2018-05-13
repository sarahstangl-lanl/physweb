-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.28-MySQL.sql' to 'ShopDb::Schema v0.29':;

BEGIN;

ALTER TABLE `shopdb`.`customers` ADD COLUMN `fax_number` varchar(255);


COMMIT;

