-- Convert schema '/home/admin/nick/git/physics/lib/ShopDb/sql/ShopDb-Schema-0.43-MySQL.sql' to 'ShopDb::Schema v0.44':;

BEGIN;

ALTER TABLE `shopdb`.`account_types` ADD COLUMN `internal` tinyint(1) NOT NULL DEFAULT 1;

ALTER TABLE `shopdb`.`accounts` ADD INDEX `setid` (`setid`),
                                ADD INDEX `fund_code` (`fund_code`),
                                ADD INDEX `deptid` (`deptid`),
                                ADD INDEX `program_code` (`program_code`),
                                ADD INDEX `project_id` (`project_id`),
                                ADD INDEX `chartfield3` (`chartfield3`),
                                ADD INDEX `chartfield1` (`chartfield1`),
                                ADD INDEX `chartfield2` (`chartfield2`),
                                ADD UNIQUE `shopdb.accounts_setid_fund_code_deptid_program_code_pro_1d6e61ad` (`setid`, `fund_code`, `deptid`, `program_code`, `project_id`, `chartfield3`, `chartfield1`, `chartfield2`);

ALTER TABLE `shopdb`.`labor_lines` DROP FOREIGN KEY `shopdb.labor_lines_fk_invoice_id`;

ALTER TABLE `shopdb`.`material_lines` DROP FOREIGN KEY `shopdb.material_lines_fk_invoice_id`;

ALTER TABLE `shopdb`.`invoices` CHANGE COLUMN `invoice_id` `invoice_id` varchar(30) NOT NULL;

ALTER TABLE `shopdb`.`labor_lines`
    CHANGE COLUMN `invoice_id` `invoice_id` varchar(30) NULL,
    ADD CONSTRAINT `shopdb.labor_lines_fk_invoice_id` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`invoice_id`);

ALTER TABLE `shopdb`.`material_lines`
    CHANGE COLUMN `invoice_id` `invoice_id` varchar(30) NULL,
    ADD CONSTRAINT `shopdb.material_lines_fk_invoice_id` FOREIGN KEY (`invoice_id`) REFERENCES `shopdb`.`invoices` (`invoice_id`);

COMMIT;

