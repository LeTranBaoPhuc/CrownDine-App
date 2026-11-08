-- =========================================================================
-- V3__Create_Missing_Tables.sql
-- Module: Banners, Chat AI Conversations & Reviews
-- =========================================================================

CREATE TABLE IF NOT EXISTS `banners` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `created_at` DATETIME(6) NULL,
  `updated_at` DATETIME(6) NULL,
  `created_by` VARCHAR(255) NULL,
  `updated_by` VARCHAR(255) NULL,
  `title` VARCHAR(100) NULL,
  `description` VARCHAR(500) NULL,
  `link_url` VARCHAR(255) NULL,
  `banner_url` VARCHAR(255) NULL,
  `status` VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chat_conversations` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `created_at` DATETIME(6) NULL,
  `updated_at` DATETIME(6) NULL,
  `created_by` VARCHAR(255) NULL,
  `updated_by` VARCHAR(255) NULL,
  `title` VARCHAR(255) NULL,
  `user_id` BIGINT NOT NULL,
  CONSTRAINT `fk_chat_conversation_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chat_messages` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `created_at` DATETIME(6) NULL,
  `updated_at` DATETIME(6) NULL,
  `created_by` VARCHAR(255) NULL,
  `updated_by` VARCHAR(255) NULL,
  `role` VARCHAR(20) NOT NULL,
  `content` TEXT NOT NULL,
  `model` VARCHAR(100) NULL,
  `conversation_id` BIGINT NOT NULL,
  CONSTRAINT `fk_chat_message_conversation` FOREIGN KEY (`conversation_id`) REFERENCES `chat_conversations`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `reviews` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `created_at` DATETIME(6) NULL,
  `updated_at` DATETIME(6) NULL,
  `created_by` VARCHAR(255) NULL,
  `updated_by` VARCHAR(255) NULL,
  `comment` VARCHAR(255) NULL,
  `customer_id` BIGINT NULL,
  CONSTRAINT `fk_review_customer` FOREIGN KEY (`customer_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
