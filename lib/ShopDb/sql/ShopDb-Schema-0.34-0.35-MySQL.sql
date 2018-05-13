-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.34-MySQL.sql' to 'ShopDb::Schema v0.35':;

BEGIN;

ALTER TABLE `shopdb`.`audit_entries` CHANGE COLUMN `result_id` `result_id` varchar(255) NOT NULL;


COMMIT;

