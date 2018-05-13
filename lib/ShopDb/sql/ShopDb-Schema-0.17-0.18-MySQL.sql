-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.17-MySQL.sql' to 'ShopDb::Schema v0.18':;

BEGIN;

ALTER TABLE `shopdb`.`estimate_labor_lines` DROP COLUMN `task`,
                                            ADD COLUMN `category` varchar(255) NOT NULL,
                                            ADD COLUMN `category_value` varchar(255) NOT NULL;

ALTER TABLE `shopdb`.`estimate_material_lines` DROP COLUMN `type`,
                                               DROP COLUMN `subtype`,
                                               ADD COLUMN `category` varchar(255) NOT NULL,
                                               ADD COLUMN `category_value` varchar(255) NOT NULL;


COMMIT;

