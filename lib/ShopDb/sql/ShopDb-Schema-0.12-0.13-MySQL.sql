-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.12-MySQL.sql' to 'ShopDb::Schema v0.13':;

BEGIN;

ALTER TABLE `shopdb`.`job_comments` CHANGE COLUMN `created_date` `created_date` date NOT NULL;


COMMIT;

