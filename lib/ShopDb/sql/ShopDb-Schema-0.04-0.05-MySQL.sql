-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.04-MySQL.sql' to 'ShopDb::Schema v0.05':;

BEGIN;

ALTER TABLE `shopdb`.`attachments` CHANGE COLUMN `uploader_id` `uploader_id` integer NOT NULL;


COMMIT;

