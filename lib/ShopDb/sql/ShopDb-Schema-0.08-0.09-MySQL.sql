-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.08-MySQL.sql' to 'ShopDb::Schema v0.09':;

BEGIN;

ALTER TABLE `shopdb`.`job_comments` DROP FOREIGN KEY `shopdb.job_comments_fk_creator_id`,
                                    DROP INDEX `shopdb.job_comments_idx_creator_id`,
                                    DROP COLUMN `creator_id`,
                                    ADD COLUMN `creator_uid` integer NOT NULL;


COMMIT;

