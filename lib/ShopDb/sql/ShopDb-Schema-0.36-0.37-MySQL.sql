-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.36-MySQL.sql' to 'ShopDb::Schema v0.37':;

BEGIN;

ALTER TABLE `shopdb`.`job_statuses` ADD COLUMN `sort_order` integer NOT NULL;


COMMIT;

