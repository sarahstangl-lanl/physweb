-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.07-MySQL.sql' to 'ShopDb::Schema v0.08':;

BEGIN;

ALTER TABLE `shopdb`.`attachments` DROP FOREIGN KEY `shopdb.attachments_fk_uploader_id`,
                                   DROP INDEX `shopdb.attachments_idx_uploader_id`,
                                   DROP COLUMN `uploader_id`,
                                   ADD COLUMN `uploader_uid` integer NOT NULL,
                                   ADD INDEX `uploader_uid` (`uploader_uid`);


COMMIT;

