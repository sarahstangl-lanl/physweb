-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Mon May 14 18:33:12 2012
-- 
SET foreign_key_checks=0;

--
-- Table: `shopdb`.`addresses`
--
CREATE TABLE `shopdb`.`addresses` (
  `address_id` integer NOT NULL auto_increment,
  `company` varchar(256),
  `lines` varchar(32768),
  PRIMARY KEY (`address_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`attachments`
--
CREATE TABLE `shopdb`.`attachments` (
  `attachment_id` integer NOT NULL auto_increment,
  `filename` varchar(255) NOT NULL,
  `size` integer NOT NULL,
  `data` mediumblob NOT NULL,
  `mime_type` varchar(255) NOT NULL,
  `upload_date` datetime NOT NULL,
  `modified_date` datetime NOT NULL,
  `uploader_uid` integer NOT NULL,
  INDEX `uploader_uid` (`uploader_uid`),
  PRIMARY KEY (`attachment_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`audit_entries`
--
CREATE TABLE `shopdb`.`audit_entries` (
  `entry_id` integer NOT NULL auto_increment,
  `directory_uid` integer NOT NULL,
  `result_type` varchar(255) NOT NULL,
  `result_id` integer NOT NULL,
  `action_type` varchar(255) NOT NULL,
  `value` varchar(2048) NOT NULL,
  `entry_date` datetime NOT NULL,
  INDEX `result_type_id` (`result_type`, `result_id`),
  INDEX `entry_date` (`entry_date`),
  PRIMARY KEY (`entry_id`)
);

--
-- Table: `shopdb`.`machinists`
--
CREATE TABLE `shopdb`.`machinists` (
  `machinist_id` integer NOT NULL auto_increment,
  `directory_uid` integer NOT NULL,
  `labor_rate` float NOT NULL,
  `shortname` varchar(5) NOT NULL,
  `fulltime` boolean NOT NULL DEFAULT '0',
  `active` boolean NOT NULL DEFAULT '1',
  PRIMARY KEY (`machinist_id`),
  UNIQUE `shopdb.machinists_shortname` (`shortname`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`shopdb_settings`
--
CREATE TABLE `shopdb`.`shopdb_settings` (
  `setting_id` integer NOT NULL auto_increment,
  `name` varchar(80) NOT NULL,
  `value` varchar(512) NOT NULL,
  `is_unique` boolean NOT NULL DEFAULT '1',
  INDEX `name` (`name`),
  PRIMARY KEY (`setting_id`),
  UNIQUE `shopdb.shopdb_settings_name_value` (`name`, `value`)
);

--
-- Table: `shopdb`.`user_preferences`
--
CREATE TABLE `shopdb`.`user_preferences` (
  `preference_id` integer NOT NULL auto_increment,
  `name` varchar(80) NOT NULL,
  `directory_uid` integer NOT NULL,
  `value` varchar(1024) NOT NULL,
  PRIMARY KEY (`preference_id`),
  UNIQUE `shopdb.user_preferences_name_directory_uid` (`name`, `directory_uid`)
);

--
-- Table: `shopdb`.`customers`
--
CREATE TABLE `shopdb`.`customers` (
  `customer_id` integer NOT NULL auto_increment,
  `directory_uid` integer NOT NULL,
  `company_name` varchar(80),
  `primary_ship_address` integer,
  `primary_bill_address` integer,
  INDEX `shopdb.customers_idx_primary_bill_address` (`primary_bill_address`),
  INDEX `shopdb.customers_idx_primary_ship_address` (`primary_ship_address`),
  PRIMARY KEY (`customer_id`),
  UNIQUE `shopdb.customers_directory_uid` (`directory_uid`),
  CONSTRAINT `shopdb.customers_fk_primary_bill_address` FOREIGN KEY (`primary_bill_address`) REFERENCES `shopdb`.`addresses` (`address_id`),
  CONSTRAINT `shopdb.customers_fk_primary_ship_address` FOREIGN KEY (`primary_ship_address`) REFERENCES `shopdb`.`addresses` (`address_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`customer_accounts`
--
CREATE TABLE `shopdb`.`customer_accounts` (
  `customer_account_id` integer NOT NULL auto_increment,
  `account_key` varchar(255) NOT NULL,
  `customer_id` integer NOT NULL,
  INDEX `shopdb.customer_accounts_idx_customer_id` (`customer_id`),
  PRIMARY KEY (`customer_account_id`),
  UNIQUE `shopdb.customer_accounts_account_key_customer_id` (`account_key`, `customer_id`),
  CONSTRAINT `shopdb.customer_accounts_fk_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `shopdb`.`customers` (`customer_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`customer_addresses`
--
CREATE TABLE `shopdb`.`customer_addresses` (
  `customer_address_id` integer NOT NULL auto_increment,
  `address_id` integer,
  `customer_id` integer,
  INDEX `shopdb.customer_addresses_idx_address_id` (`address_id`),
  INDEX `shopdb.customer_addresses_idx_customer_id` (`customer_id`),
  PRIMARY KEY (`customer_address_id`),
  UNIQUE `shopdb.customer_addresses_address_id_customer_id` (`address_id`, `customer_id`),
  CONSTRAINT `shopdb.customer_addresses_fk_address_id` FOREIGN KEY (`address_id`) REFERENCES `shopdb`.`addresses` (`address_id`),
  CONSTRAINT `shopdb.customer_addresses_fk_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `shopdb`.`customers` (`customer_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`jobs`
--
CREATE TABLE `shopdb`.`jobs` (
  `job_id` integer NOT NULL auto_increment,
  `parent_job_id` integer,
  `customer_id` integer,
  `pi_id` integer,
  `property_id` varchar(255),
  `account_key` varchar(255),
  `project_name` varchar(255) NOT NULL,
  `instructions` varchar(255),
  `justification` varchar(255),
  `creation_date` date NOT NULL,
  `in_date` date,
  `need_date` date,
  `finish_date` date,
  `ship_date` date,
  `customer_po_num` varchar(255),
  `contact_number` varchar(255),
  `ship_address_id` integer,
  `bill_address_id` integer,
  `approved_date` date,
  `needs_shipping` bool NOT NULL DEFAULT '0',
  `external` bool NOT NULL DEFAULT '0',
  `projected_charge_hours` integer,
  `projected_labor_cost` integer,
  `projected_material_cost` integer,
  `entry_machinist_id` integer,
  INDEX `shopdb.jobs_idx_bill_address_id` (`bill_address_id`),
  INDEX `shopdb.jobs_idx_customer_id` (`customer_id`),
  INDEX `shopdb.jobs_idx_entry_machinist_id` (`entry_machinist_id`),
  INDEX `shopdb.jobs_idx_parent_job_id` (`parent_job_id`),
  INDEX `shopdb.jobs_idx_pi_id` (`pi_id`),
  INDEX `shopdb.jobs_idx_ship_address_id` (`ship_address_id`),
  INDEX `external` (`external`),
  PRIMARY KEY (`job_id`),
  CONSTRAINT `shopdb.jobs_fk_bill_address_id` FOREIGN KEY (`bill_address_id`) REFERENCES `shopdb`.`addresses` (`address_id`),
  CONSTRAINT `shopdb.jobs_fk_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `shopdb`.`customers` (`customer_id`),
  CONSTRAINT `shopdb.jobs_fk_entry_machinist_id` FOREIGN KEY (`entry_machinist_id`) REFERENCES `shopdb`.`machinists` (`machinist_id`),
  CONSTRAINT `shopdb.jobs_fk_parent_job_id` FOREIGN KEY (`parent_job_id`) REFERENCES `shopdb`.`jobs` (`job_id`),
  CONSTRAINT `shopdb.jobs_fk_pi_id` FOREIGN KEY (`pi_id`) REFERENCES `shopdb`.`customers` (`customer_id`),
  CONSTRAINT `shopdb.jobs_fk_ship_address_id` FOREIGN KEY (`ship_address_id`) REFERENCES `shopdb`.`addresses` (`address_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`invoices`
--
CREATE TABLE `shopdb`.`invoices` (
  `invoice_id` integer NOT NULL auto_increment,
  `job_id` integer NOT NULL,
  `pdf` mediumblob NOT NULL,
  `bill_date` date,
  `paid_date` date,
  `creation_date` date NOT NULL,
  `creator_uid` integer NOT NULL,
  `account_key` varchar(255) NOT NULL,
  INDEX `shopdb.invoices_idx_job_id` (`job_id`),
  PRIMARY KEY (`invoice_id`),
  CONSTRAINT `shopdb.invoices_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`job_assignments`
--
CREATE TABLE `shopdb`.`job_assignments` (
  `job_assignment_id` integer NOT NULL auto_increment,
  `job_id` integer NOT NULL,
  `machinist_id` integer NOT NULL,
  INDEX `shopdb.job_assignments_idx_job_id` (`job_id`),
  INDEX `shopdb.job_assignments_idx_machinist_id` (`machinist_id`),
  PRIMARY KEY (`job_assignment_id`),
  UNIQUE `shopdb.job_assignments_job_id_machinist_id` (`job_id`, `machinist_id`),
  CONSTRAINT `shopdb.job_assignments_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`),
  CONSTRAINT `shopdb.job_assignments_fk_machinist_id` FOREIGN KEY (`machinist_id`) REFERENCES `shopdb`.`machinists` (`machinist_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`job_comments`
--
CREATE TABLE `shopdb`.`job_comments` (
  `job_comment_id` integer NOT NULL auto_increment,
  `comment` text NOT NULL,
  `job_id` integer NOT NULL,
  `creator_uid` integer NOT NULL,
  `customer_visible` boolean NOT NULL DEFAULT '0',
  `include_on_invoice` boolean NOT NULL DEFAULT '0',
  `created_date` date NOT NULL,
  INDEX `shopdb.job_comments_idx_job_id` (`job_id`),
  PRIMARY KEY (`job_comment_id`),
  CONSTRAINT `shopdb.job_comments_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`job_attachments`
--
CREATE TABLE `shopdb`.`job_attachments` (
  `job_attachment_id` integer NOT NULL auto_increment,
  `job_id` integer NOT NULL,
  `attachment_id` integer NOT NULL,
  INDEX `shopdb.job_attachments_idx_attachment_id` (`attachment_id`),
  INDEX `shopdb.job_attachments_idx_job_id` (`job_id`),
  PRIMARY KEY (`job_attachment_id`),
  UNIQUE `shopdb.job_attachments_job_id_attachment_id` (`job_id`, `attachment_id`),
  CONSTRAINT `shopdb.job_attachments_fk_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `shopdb`.`attachments` (`attachment_id`),
  CONSTRAINT `shopdb.job_attachments_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`labor_lines`
--
CREATE TABLE `shopdb`.`labor_lines` (
  `labor_line_id` integer NOT NULL auto_increment,
  `job_id` integer NOT NULL,
  `description` varchar(255) NOT NULL,
  `charge_date` date NOT NULL,
  `charge_hours` float NOT NULL DEFAULT 0,
  `override_cost` float,
  `machinist_id` integer NOT NULL,
  `invoice_id` integer,
  `bill_date` date,
  `paid_date` date,
  `finalized` boolean NOT NULL DEFAULT '0',
  `active` boolean NOT NULL DEFAULT '1',
  INDEX `shopdb.labor_lines_idx_invoice_id` (`invoice_id`),
  INDEX `shopdb.labor_lines_idx_job_id` (`job_id`),
  INDEX `shopdb.labor_lines_idx_machinist_id` (`machinist_id`),
  PRIMARY KEY (`labor_line_id`),
  CONSTRAINT `shopdb.labor_lines_fk_invoice_id` FOREIGN KEY (`invoice_id`) REFERENCES `shopdb`.`invoices` (`invoice_id`),
  CONSTRAINT `shopdb.labor_lines_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`),
  CONSTRAINT `shopdb.labor_lines_fk_machinist_id` FOREIGN KEY (`machinist_id`) REFERENCES `shopdb`.`machinists` (`machinist_id`)
) ENGINE=InnoDB;

--
-- Table: `shopdb`.`material_lines`
--
CREATE TABLE `shopdb`.`material_lines` (
  `material_line_id` integer NOT NULL auto_increment,
  `job_id` integer NOT NULL,
  `quantity` integer NOT NULL,
  `unit` varchar(255) NOT NULL,
  `unit_cost` float,
  `override_cost` float,
  `description` varchar(255) NOT NULL,
  `charge_date` date NOT NULL,
  `machinist_id` integer NOT NULL,
  `invoice_id` integer,
  `bill_date` date,
  `paid_date` date,
  `finalized` boolean NOT NULL DEFAULT '0',
  `active` boolean NOT NULL DEFAULT '1',
  INDEX `shopdb.material_lines_idx_invoice_id` (`invoice_id`),
  INDEX `shopdb.material_lines_idx_job_id` (`job_id`),
  INDEX `shopdb.material_lines_idx_machinist_id` (`machinist_id`),
  PRIMARY KEY (`material_line_id`),
  CONSTRAINT `shopdb.material_lines_fk_invoice_id` FOREIGN KEY (`invoice_id`) REFERENCES `shopdb`.`invoices` (`invoice_id`),
  CONSTRAINT `shopdb.material_lines_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `shopdb`.`jobs` (`job_id`),
  CONSTRAINT `shopdb.material_lines_fk_machinist_id` FOREIGN KEY (`machinist_id`) REFERENCES `shopdb`.`machinists` (`machinist_id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

