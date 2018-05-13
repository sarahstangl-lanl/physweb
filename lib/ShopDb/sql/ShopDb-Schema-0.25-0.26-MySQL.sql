-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.25-MySQL.sql' to 'ShopDb::Schema v0.26':;

BEGIN;

ALTER TABLE `shopdb`.`packing_slip_lines` DROP COLUMN `quantity_backordered`;

ALTER TABLE `shopdb`.`packing_slips` DROP COLUMN `quantity_backordered`;


COMMIT;

