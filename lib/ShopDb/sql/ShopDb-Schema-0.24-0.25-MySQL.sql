-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.24-MySQL.sql' to 'ShopDb::Schema v0.25':;

BEGIN;

ALTER TABLE `shopdb`.`packing_slips` ADD COLUMN `ship_address_id` integer NOT NULL,
                                     ADD INDEX `shopdb.packing_slips_idx_ship_address_id` (`ship_address_id`),
                                     ADD CONSTRAINT `shopdb.packing_slips_fk_ship_address_id` FOREIGN KEY (`ship_address_id`) REFERENCES `shopdb`.`addresses` (`address_id`);


COMMIT;

