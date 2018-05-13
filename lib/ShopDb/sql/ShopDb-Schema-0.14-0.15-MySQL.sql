-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.14-MySQL.sql' to 'ShopDb::Schema v0.15':;

BEGIN;

ALTER TABLE `shopdb`.`jobs` ADD COLUMN `status` varchar(128) NOT NULL,
                            ADD COLUMN `status_comment` varchar(1024);


COMMIT;

