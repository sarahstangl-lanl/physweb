-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.11-MySQL.sql' to 'ShopDb::Schema v0.12':;

BEGIN;

ALTER TABLE `shopdb`.`addresses` DROP COLUMN `attention`,
                                 DROP COLUMN `line1`,
                                 DROP COLUMN `line2`,
                                 DROP COLUMN `city`,
                                 DROP COLUMN `state`,
                                 DROP COLUMN `zip`,
                                 DROP COLUMN `country`,
                                 ADD COLUMN `lines` varchar(32768),
                                 CHANGE COLUMN `company` `company` varchar(256);


COMMIT;

