-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.01-MySQL.sql' to 'ShopDb::Schema v0.02':;

BEGIN;

ALTER TABLE `shopdb`.`shopdb_settings` CHANGE COLUMN `value` `value` varchar(512) NOT NULL,
                                       ADD UNIQUE `shopdb.shopdb_settings_name_value` (`name`, `value`);


COMMIT;

