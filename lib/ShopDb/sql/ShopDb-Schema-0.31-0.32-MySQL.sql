-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.31-MySQL.sql' to 'ShopDb::Schema v0.32':;

BEGIN;

ALTER TABLE `shopdb`.`jobs` ADD COLUMN `filemaker_job_id` integer,
                            ADD COLUMN `ship_date` date;


COMMIT;

