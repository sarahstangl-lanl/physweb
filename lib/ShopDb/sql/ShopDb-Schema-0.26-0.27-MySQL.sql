-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.26-MySQL.sql' to 'ShopDb::Schema v0.27':;

BEGIN;

ALTER TABLE `shopdb`.`jobs` ADD COLUMN `modified_date` datetime NOT NULL;

ALTER TABLE `shopdb`.`packing_slip_lines` ADD COLUMN `is_comment` boolean NOT NULL DEFAULT '0';


COMMIT;

