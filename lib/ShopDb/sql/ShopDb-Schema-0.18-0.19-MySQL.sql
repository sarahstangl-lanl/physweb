-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.18-MySQL.sql' to 'ShopDb::Schema v0.19':;

BEGIN;

ALTER TABLE `shopdb`.`job_estimates` ADD COLUMN `labor_rate` float NOT NULL,
                                     ADD COLUMN `edm_labor_rate` float NOT NULL;


COMMIT;

