-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.37-MySQL.sql' to 'ShopDb::Schema v0.38':;

BEGIN;

ALTER TABLE `shopdb`.`jobs` ADD COLUMN `customer_ref_1` varchar(255),
                            ADD COLUMN `customer_ref_2` varchar(255);


COMMIT;

