-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.03-MySQL.sql' to 'ShopDb::Schema v0.04':;

BEGIN;

ALTER TABLE `shopdb`.`audit_entries` ADD INDEX `result_type_id` (`result_type`, `result_id`),
                                     ADD INDEX `entry_date` (`entry_date`);


COMMIT;

