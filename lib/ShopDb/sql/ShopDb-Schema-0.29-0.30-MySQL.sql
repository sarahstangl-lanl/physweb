-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.29-MySQL.sql' to 'ShopDb::Schema v0.30':;

BEGIN;

ALTER TABLE `shopdb`.`jobs` CHANGE COLUMN `quantity_ordered` `quantity_ordered` integer NOT NULL DEFAULT 0,
                            CHANGE COLUMN `quantity_shipped` `quantity_shipped` integer NOT NULL DEFAULT 0;


COMMIT;

