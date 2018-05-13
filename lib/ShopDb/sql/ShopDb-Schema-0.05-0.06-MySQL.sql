-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.05-MySQL.sql' to 'ShopDb::Schema v0.06':;

BEGIN;

ALTER TABLE `shopdb`.`machinists` ADD COLUMN `active` boolean NOT NULL DEFAULT '1';


COMMIT;

