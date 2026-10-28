-- =========================================================================
-- CrownDine Flyway Migration: V1__Init.sql
-- Consolidated Schema & Initial Data
-- =========================================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `favorites`;
DROP TABLE IF EXISTS `point_histories`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `feedbacks`;
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `order_details`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `reservations`;
DROP TABLE IF EXISTS `user_vouchers`;
DROP TABLE IF EXISTS `vouchers`;
DROP TABLE IF EXISTS `combo_items`;
DROP TABLE IF EXISTS `combos`;
DROP TABLE IF EXISTS `items`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `restaurant_tables`;
DROP TABLE IF EXISTS `areas`;
DROP TABLE IF EXISTS `floors`;
DROP TABLE IF EXISTS `tokens`;
DROP TABLE IF EXISTS `user_roles`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `roles`;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. roles
CREATE TABLE `roles` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` enum('ADMIN','STAFF','USER') NOT NULL,
    `description` varchar(500) DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_roles_name` UNIQUE (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. users
CREATE TABLE `users` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `username` varchar(50) NOT NULL,
    `avatar_url` varchar(200) DEFAULT NULL,
    `password` varchar(255) DEFAULT NULL,
    `email` varchar(255) NOT NULL,
    `first_name` varchar(50) NOT NULL,
    `last_name` varchar(50) NOT NULL,
    `date_of_birth` date DEFAULT NULL,
    `gender` enum('FEMALE','MALE','OTHER') DEFAULT NULL,
    `status` enum('ACTIVE','BANNED','INACTIVE') NOT NULL,
    `phone` varchar(11) DEFAULT NULL,
    `google_id` varchar(255) DEFAULT NULL,
    `verification_code` varchar(255) DEFAULT NULL,
    `verification_expiration` datetime(6) DEFAULT NULL,
    `reward_points` int NOT NULL DEFAULT 0,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_users_username` UNIQUE (`username`),
    CONSTRAINT `uk_users_email` UNIQUE (`email`),
    CONSTRAINT `uk_users_phone` UNIQUE (`phone`),
    CONSTRAINT `uk_users_google_id` UNIQUE (`google_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. user_roles
CREATE TABLE `user_roles` (
    `user_id` bigint NOT NULL,
    `role_id` bigint NOT NULL,
    PRIMARY KEY (`user_id`, `role_id`),
    CONSTRAINT `fk_user_roles_user_id_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_user_roles_role_id_roles` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. tokens
CREATE TABLE `tokens` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `username` varchar(255) NOT NULL,
    `token` text,
    `refresh_token` varchar(1000) DEFAULT NULL,
    `device` varchar(1000) DEFAULT NULL,
    `ip_address` varchar(45) DEFAULT NULL,
    `is_revoked` bit(1) DEFAULT NULL,
    `expired_at` datetime(6) DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. floors
CREATE TABLE `floors` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `floor_number` int DEFAULT NULL,
    `description` varchar(500) DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. areas
CREATE TABLE `areas` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `description` varchar(500) DEFAULT NULL,
    `floor_id` bigint NOT NULL,
    `x` double DEFAULT NULL,
    `y` double DEFAULT NULL,
    `width` double DEFAULT NULL,
    `height` double DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_areas_floor_id_floors` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. restaurant_tables
CREATE TABLE `restaurant_tables` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(50) DEFAULT NULL,
    `capacity` int DEFAULT NULL,
    `status` enum('AVAILABLE','OCCUPIED','RESERVED','UNAVAILABLE') NOT NULL DEFAULT 'AVAILABLE',
    `shape` enum('CIRCLE','RECT','SQUARE') NOT NULL DEFAULT 'SQUARE',
    `base_deposit` decimal(12,2) DEFAULT NULL,
    `position_x` int DEFAULT NULL,
    `position_y` int DEFAULT NULL,
    `width` int DEFAULT NULL,
    `height` int DEFAULT NULL,
    `rotation` int DEFAULT NULL,
    `image_url` varchar(500) DEFAULT NULL,
    `description` text,
    `area_id` bigint DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_restaurant_tables_area_id` (`area_id`),
    CONSTRAINT `fk_restaurant_tables_area_id_areas` FOREIGN KEY (`area_id`) REFERENCES `areas` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. categories
CREATE TABLE `categories` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(255) DEFAULT NULL,
    `slug` varchar(255) DEFAULT NULL,
    `description` varchar(255) DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. items
CREATE TABLE `items` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(255) DEFAULT NULL,
    `slug` varchar(255) DEFAULT NULL,
    `description` text DEFAULT NULL,
    `price` decimal(38,2) DEFAULT NULL,
    `price_after_discount` decimal(38,2) DEFAULT NULL,
    `sold_count` bigint DEFAULT 0,
    `status` enum('AVAILABLE','UNAVAILABLE') DEFAULT 'AVAILABLE',
    `image_url` varchar(500) DEFAULT NULL,
    `category_id` bigint DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_items_category_id` (`category_id`),
    CONSTRAINT `fk_items_category_id_categories` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. combos
CREATE TABLE `combos` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(255) DEFAULT NULL,
    `slug` varchar(255) DEFAULT NULL,
    `description` varchar(255) DEFAULT NULL,
    `price` decimal(38,2) DEFAULT NULL,
    `price_after_discount` decimal(38,2) DEFAULT NULL,
    `sold_count` bigint DEFAULT 0,
    `status` enum('AVAILABLE','UNAVAILABLE') DEFAULT 'AVAILABLE',
    `image_url` varchar(500) DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. combo_items
CREATE TABLE `combo_items` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `combo_id` bigint DEFAULT NULL,
    `item_id` bigint DEFAULT NULL,
    `quantity` int DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_combo_items_combo_id` (`combo_id`),
    KEY `idx_combo_items_item_id` (`item_id`),
    CONSTRAINT `fk_combo_items_combo_id_combos` FOREIGN KEY (`combo_id`) REFERENCES `combos` (`id`),
    CONSTRAINT `fk_combo_items_item_id_items` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. vouchers
CREATE TABLE `vouchers` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(100) DEFAULT NULL,
    `code` varchar(100) DEFAULT NULL,
    `type` enum('FIXED_AMOUNT','PERCENTAGE') DEFAULT NULL,
    `discount_value` decimal(38,2) DEFAULT NULL,
    `max_discount_value` decimal(38,2) DEFAULT NULL,
    `min_value` decimal(38,2) DEFAULT NULL,
    `points_required` int DEFAULT NULL,
    `description` varchar(255) DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_vouchers_code` UNIQUE (`code`),
    CONSTRAINT `uk_vouchers_name` UNIQUE (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 13. user_vouchers
CREATE TABLE `user_vouchers` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `customer_id` bigint DEFAULT NULL,
    `voucher_id` bigint DEFAULT NULL,
    `usage_count` int NOT NULL DEFAULT 0,
    `usage_limit` int NOT NULL DEFAULT 1,
    `assigned_at` datetime(6) DEFAULT CURRENT_TIMESTAMP(6),
    `expired_at` datetime(6) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_user_vouchers_customer_id` (`customer_id`),
    KEY `idx_user_vouchers_voucher_id` (`voucher_id`),
    CONSTRAINT `fk_user_vouchers_customer_id_users` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_user_vouchers_voucher_id_vouchers` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 14. reservations
CREATE TABLE `reservations` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `code` varchar(255) NOT NULL,
    `customer_id` bigint DEFAULT NULL,
    `restaurant_table_id` bigint DEFAULT NULL,
    `created_by_staff_id` bigint DEFAULT NULL,
    `date` date DEFAULT NULL,
    `start_time` time(6) DEFAULT NULL,
    `end_time` time(6) DEFAULT NULL,
    `checked_out_at` datetime(6) DEFAULT NULL,
    `reminder_sent_at` datetime(6) DEFAULT NULL,
    `expirated_at` datetime(6) DEFAULT NULL,
    `guest_number` int DEFAULT NULL,
    `guest_name` varchar(100) DEFAULT NULL,
    `guest_phone` varchar(255) DEFAULT NULL,
    `note` varchar(255) DEFAULT NULL,
    `status` enum('CANCELLED','CHECKED_IN','COMPLETED','CONFIRMED','NO_SHOW','PENDING') DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_reservations_code` UNIQUE (`code`),
    KEY `idx_reservations_customer_id` (`customer_id`),
    KEY `idx_reservations_restaurant_table_id` (`restaurant_table_id`),
    KEY `idx_reservations_created_by_staff_id` (`created_by_staff_id`),
    KEY `idx_reservations_status_date_start_checked_out` (`status`, `date`, `start_time`, `checked_out_at`),
    KEY `idx_reservations_table_date_status_checked_out_exp` (`restaurant_table_id`, `date`, `status`, `checked_out_at`, `expirated_at`),
    CONSTRAINT `fk_reservations_customer_id_users` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_reservations_restaurant_table_id_restaurant_tables` FOREIGN KEY (`restaurant_table_id`) REFERENCES `restaurant_tables` (`id`),
    CONSTRAINT `fk_reservations_created_by_staff_id_users` FOREIGN KEY (`created_by_staff_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 15. orders
CREATE TABLE `orders` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `code` varchar(255) NOT NULL,
    `user_id` bigint DEFAULT NULL,
    `staff_id` bigint DEFAULT NULL,
    `reservation_id` bigint DEFAULT NULL,
    `restaurant_table_id` bigint DEFAULT NULL,
    `voucher_id` bigint DEFAULT NULL,
    `total_price` decimal(38,2) DEFAULT NULL,
    `discount_price` decimal(38,2) DEFAULT NULL,
    `final_price` decimal(38,2) DEFAULT NULL,
    `status` enum('CANCELLED','COMPLETED','CONFIRMED','IN_PROGRESS','PENDING','PRE_ORDER','SERVED') DEFAULT NULL,
    `cancel_reason` varchar(255) DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_orders_code` UNIQUE (`code`),
    CONSTRAINT `uk_orders_reservation_id` UNIQUE (`reservation_id`),
    KEY `idx_orders_user_id` (`user_id`),
    KEY `idx_orders_staff_id` (`staff_id`),
    KEY `idx_orders_restaurant_table_id` (`restaurant_table_id`),
    KEY `idx_orders_voucher_id` (`voucher_id`),
    CONSTRAINT `fk_orders_user_id_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_orders_staff_id_users` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_orders_reservation_id_reservations` FOREIGN KEY (`reservation_id`) REFERENCES `reservations` (`id`),
    CONSTRAINT `fk_orders_restaurant_table_id_restaurant_tables` FOREIGN KEY (`restaurant_table_id`) REFERENCES `restaurant_tables` (`id`),
    CONSTRAINT `fk_orders_voucher_id_vouchers` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 16. order_details
CREATE TABLE `order_details` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `order_id` bigint DEFAULT NULL,
    `item_id` bigint DEFAULT NULL,
    `combo_id` bigint DEFAULT NULL,
    `quantity` int DEFAULT NULL,
    `total_price` decimal(38,2) DEFAULT NULL,
    `status` enum('CANCELLED','COMPLETED','COOKING','PENDING','READY','SERVED') DEFAULT 'PENDING',
    `note` varchar(255) DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_order_details_order_id` (`order_id`),
    KEY `idx_order_details_item_id` (`item_id`),
    KEY `idx_order_details_combo_id` (`combo_id`),
    CONSTRAINT `fk_order_details_order_id_orders` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
    CONSTRAINT `fk_order_details_item_id_items` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
    CONSTRAINT `fk_order_details_combo_id_combos` FOREIGN KEY (`combo_id`) REFERENCES `combos` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 17. payments
CREATE TABLE `payments` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `code` bigint NOT NULL,
    `amount` decimal(38,2) DEFAULT NULL,
    `transaction_code` varchar(255) DEFAULT NULL,
    `raw_api_data` text,
    `method` enum('BANK_TRANSFER','CASH','INTERNAL_WALLET','MOMO','OTHER','PAYOS','VNPAY','ZALO_PAY') DEFAULT NULL,
    `status` enum('CANCELLED','EXPIRED','FAILED','PAID','PENDING','REFUNDED') DEFAULT NULL,
    `type` enum('PAYMENT','REFUND') DEFAULT NULL,
    `target` enum('BILL_SETTLEMENT','RESERVATION_DEPOSIT') DEFAULT NULL,
    `source` enum('CASHIER','CUSTOMER_ONLINE','STAFF_MOBILE') DEFAULT NULL,
    `reservation_id` bigint DEFAULT NULL,
    `order_id` bigint DEFAULT NULL,
    `user_id` bigint NOT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_payments_code` UNIQUE (`code`),
    KEY `idx_payments_reservation_id` (`reservation_id`),
    KEY `idx_payments_order_id` (`order_id`),
    KEY `idx_payments_user_id` (`user_id`),
    CONSTRAINT `fk_payments_reservation_id_reservations` FOREIGN KEY (`reservation_id`) REFERENCES `reservations` (`id`),
    CONSTRAINT `fk_payments_order_id_orders` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
    CONSTRAINT `fk_payments_user_id_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 18. feedbacks
CREATE TABLE `feedbacks` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `rating` int DEFAULT NULL,
    `comment` varchar(200) DEFAULT NULL,
    `guest_name` varchar(100) DEFAULT NULL,
    `guest_email` varchar(255) DEFAULT NULL,
    `is_featured` bit(1) DEFAULT b'0',
    `status` enum('APPROVED','HIDDEN','PENDING','REJECTED') DEFAULT 'APPROVED',
    `item_id` bigint DEFAULT NULL,
    `combo_id` bigint DEFAULT NULL,
    `order_id` bigint DEFAULT NULL,
    `order_detail_id` bigint DEFAULT NULL,
    `user_id` bigint DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_feedbacks_item_id` (`item_id`),
    KEY `idx_feedbacks_combo_id` (`combo_id`),
    KEY `idx_feedbacks_order_id` (`order_id`),
    KEY `idx_feedbacks_order_detail_id` (`order_detail_id`),
    KEY `idx_feedbacks_user_id` (`user_id`),
    CONSTRAINT `uq_feedbacks_user_order` UNIQUE (`user_id`, `order_id`),
    CONSTRAINT `fk_feedbacks_item_id_items` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
    CONSTRAINT `fk_feedbacks_combo_id_combos` FOREIGN KEY (`combo_id`) REFERENCES `combos` (`id`),
    CONSTRAINT `fk_feedbacks_order_id_orders` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
    CONSTRAINT `fk_feedbacks_order_detail_id_order_details` FOREIGN KEY (`order_detail_id` ) REFERENCES `order_details` (`id`),
    CONSTRAINT `fk_feedbacks_user_id_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 19. notifications
CREATE TABLE `notifications` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `user_id` bigint NOT NULL,
    `type` enum('VOUCHER_GRANTED','VOUCHER_EXPIRING_SOON','VOUCHER_EXPIRED','RESERVATION_CONFIRMED','RESERVATION_REMINDER') NOT NULL,
    `title` varchar(255) NOT NULL,
    `message` varchar(500) NOT NULL,
    `payload` json DEFAULT NULL,
    `read_at` datetime(6) DEFAULT NULL,
    `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id`),
    KEY `idx_notifications_user_id` (`user_id`),
    KEY `idx_notifications_type` (`type`),
    KEY `idx_notifications_read_at` (`read_at`),
    KEY `idx_notifications_created_at` (`created_at`),
    CONSTRAINT `fk_notifications_user_id_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 20. point_histories
CREATE TABLE `point_histories` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `user_id` bigint NOT NULL,
    `points_changed` int NOT NULL,
    `reason` enum('ADMIN_ADJUSTMENT','EARN_FROM_ORDER','SPEND_ON_VOUCHER') NOT NULL,
    `reference_id` bigint DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_point_histories_user_id` (`user_id`),
    CONSTRAINT `fk_point_histories_user_id_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 21. favorites
CREATE TABLE `favorites` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `user_id` bigint NOT NULL,
    `item_id` bigint DEFAULT NULL,
    `combo_id` bigint DEFAULT NULL,
    `created_at` datetime(6) DEFAULT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `created_by` varchar(255) DEFAULT NULL,
    `updated_by` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_favorites_user_id` (`user_id`),
    KEY `idx_favorites_item_id` (`item_id`),
    KEY `idx_favorites_combo_id` (`combo_id`),
    CONSTRAINT `fk_favorites_user_id_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_favorites_item_id_items` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_favorites_combo_id_combos` FOREIGN KEY (`combo_id`) REFERENCES `combos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================================
-- INITIAL DATA
-- =========================================================================


INSERT INTO roles (id, name, description, created_at, updated_at)
VALUES (1, 'ADMIN', 'Quản trị hệ thống', NOW(), NOW()),
       (2, 'STAFF', 'Nhân viên nhà hàng', NOW(), NOW()),
       (3, 'USER', 'Khách hàng', NOW(), NOW());


-- 1. Thêm Tầng (Floors)
INSERT INTO `floors` (`name`, `floor_number`, `description`, `created_at`, `updated_at`)
VALUES ('Tầng 1', 1, 'Khu vực trong nhà chính và phòng VIP', NOW(), NOW()),
       ('Tầng 2', 2, 'Khu vực ngoài trời và sân thượng', NOW(), NOW());


-- 2. Thêm Khu Vực (Areas) - Tránh overlap, canh chỉnh perfect margin
-- Tầng 1 (floor_id = 1)
INSERT INTO `areas` (`name`, `description`, `floor_id`, `x`, `y`, `width`, `height`, `created_at`, `updated_at`)
VALUES ('Sảnh chính', 'Khu vực ăn uống chung rộng rãi', 1, 420, 275, 410, 250, NOW(), NOW()),
       ('Phòng VIP 1', 'Phòng riêng cho 10 người', 1, 416, 100, 200, 150, NOW(), NOW()),
       ('Phòng VIP 2', 'Phòng tụ họp gia đình', 1, 630, 100, 200, 150, NOW(), NOW()),
       ('Phòng VIP 3', '', 1, 850, 275, 200, 250, NOW(), NOW()),
       ('Phòng VIP 4', '', 1, 200, 275, 200, 250, NOW(), NOW()),
       ('Sân thượng', 'Khu vực ngoài trời thoáng mát', 2, 420, 275, 410, 250, NOW(), NOW()),
       ('Ban công BBQ', 'Khu chuyên nướng BBQ', 2, 850, 275, 200, 250, NOW(), NOW()),
       ('Phòng VIP 5', '', 2, 416, 100, 200, 150, NOW(), NOW()),
       ('Phòng VIP 6', NULL, 2, 630, 100, 200, 150, NOW(), NOW()),
       ('Phòng VIP 7', NULL, 2, 200, 275, 200, 250, NOW(), NOW());

-- 3. Thêm Bàn (Tables)
INSERT INTO `restaurant_tables`
(`name`, `capacity`, `status`, `base_deposit`, `position_x`, `position_y`, `width`, `height`, `rotation`, `shape`,
 `area_id`, `image_url`, `description`, `created_at`, `updated_at`)
VALUES
-- Area 1: Sảnh chính (ID 1)
('SC-1', 6, 'AVAILABLE', 0.00, -280, -180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn 6 người sang trọng view trung tâm sảnh.', NOW(), NOW()),
('SC-2', 6, 'AVAILABLE', 0.00, -80, -180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn 6 người khu vực trung tâm, không gian thoáng đãng.', NOW(), NOW()),
('SC-3', 6, 'AVAILABLE', 0.00, 855, 80, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Góc bàn riêng tư cạnh cửa sổ, nhìn ra sảnh chính.', NOW(), NOW()),
('SC-4', 6, 'AVAILABLE', 0.00, 120, -180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Vị trí lý tưởng để quan sát các buổi biểu diễn âm nhạc.', NOW(), NOW()),
('SC-5', 6, 'AVAILABLE', 0.00, 520, 180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn tiệc gia đình ấm cúng tại sảnh tầng 1.', NOW(), NOW()),
('SC-6', 6, 'AVAILABLE', 0.00, 855, 330, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Khu trung tâm sảnh, phù hợp cho nhóm bạn trẻ năng động.', NOW(), NOW()),
('SC-7', 10, 'AVAILABLE', 0.00, -280, 0, 200, 90, 0, 'RECT', 1,
 'https://ak1.ostkcdn.com/images/products/is/images/direct/c5b3c26487fe7b03dadb2b2f4dbb5d0dff12e1c6/10-Person-Extendable-63%27%27-to-94.5%27%27-Dining-Set%2CRectangular-Sintered-Stone-Top%2CStainless-Steel-Legs%281-Table-10-Polo-Chairs%29.jpg?impolicy=medium',
 'Bàn tiệc lớn 10 người, không gian rộng rãi thoải mái.', NOW(), NOW()),
('SC-8', 10, 'AVAILABLE', 0.00, 70, 0, 200, 90, 0, 'RECT', 1,
 'https://ak1.ostkcdn.com/images/products/is/images/direct/c5b3c26487fe7b03dadb2b2f4dbb5d0dff12e1c6/10-Person-Extendable-63%27%27-to-94.5%27%27-Dining-Set%2CRectangular-Sintered-Stone-Top%2CStainless-Steel-Legs%281-Table-10-Polo-Chairs%29.jpg?impolicy=medium',
 'Bàn dài cao cấp cho nhóm hội nghị hoặc đại gia đình.', NOW(), NOW()),
('SC-9', 6, 'AVAILABLE', 100000.00, 320, -180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn vip tiêu chuẩn tại sảnh chính, phục vụ tận tâm.', NOW(), NOW()),
('SC-10', 6, 'AVAILABLE', 100000.00, 520, -180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Không gian sảnh thượng lưu, trang trí hoa tươi tinh tế.', NOW(), NOW()),
('SC-11', 10, 'AVAILABLE', 100000.00, 410, 0, 200, 90, 0, 'RECT', 1,
 'https://ak1.ostkcdn.com/images/products/is/images/direct/c5b3c26487fe7b03dadb2b2f4dbb5d0dff12e1c6/10-Person-Extendable-63%27%27-to-94.5%27%27-Dining-Set%2CRectangular-Sintered-Stone-Top%2CStainless-Steel-Legs%281-Table-10-Polo-Chairs%29.jpg?impolicy=medium',
 'Khu bàn tiệc dài sảnh chính, riêng tư vừa đủ.', NOW(), NOW()),
('SC-12', 6, 'AVAILABLE', 100000.00, -280, 180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Góc bàn sảnh gần quầy bar, không khí sôi động.', NOW(), NOW()),
('SC-13', 6, 'AVAILABLE', 100000.00, -80, 180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Vị trí gần lối vào, trang trí phong cách Châu Âu.', NOW(), NOW()),
('SC-14', 6, 'AVAILABLE', 100000.00, 320, 180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Khu trung tâm sảnh, thích hợp cho các cặp đôi.', NOW(), NOW()),
('SC-15', 6, 'AVAILABLE', 100000.00, 120, 180, 90, 90, 0, 'SQUARE', 1,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn sảnh thanh lịch, không gian xanh mát.', NOW(), NOW()),

-- Area 2: Phòng VIP 1 (ID 2)
('VIP1-1', 10, 'AVAILABLE', 500000.00, 0, 100, 359, 160, 0, 'RECT', 2,
 'https://ak1.ostkcdn.com/images/products/is/images/direct/c5b3c26487fe7b03dadb2b2f4dbb5d0dff12e1c6/10-Person-Extendable-63%27%27-to-94.5%27%27-Dining-Set%2CRectangular-Sintered-Stone-Top%2CStainless-Steel-Legs%281-Table-10-Polo-Chairs%29.jpg?impolicy=medium',
 'Phòng VIP 1 với không gian hoàn toàn riêng tư cho 10 khách.', NOW(), NOW()),

-- Area 3: Phòng VIP 2 (ID 3)
('VIP2-1', 8, 'AVAILABLE', 200000.00, -350, 100, 240, 240, 0, 'CIRCLE', 3,
 'https://assets.wfcdn.com/im/14684299/compr-r85/2280/228059320/Aryhanna+8+-+Person+Solid+Wood+Top+Pedestal+Dining+Set.jpg',
 'Bàn tròn lớn tại Phòng VIP 2, lý tưởng cho tiệc gia đình.', NOW(), NOW()),
('VIP2-2', 8, 'AVAILABLE', 200000.00, 20, 100, 240, 240, 0, 'CIRCLE', 3,
 'https://assets.wfcdn.com/im/14684299/compr-r85/2280/228059320/Aryhanna+8+-+Person+Solid+Wood+Top+Pedestal+Dining+Set.jpg',
 'Không gian ấm cúng, riêng tư tuyệt đối cho nhóm 8 người.', NOW(), NOW()),

-- Area 4: Phòng VIP 3 (ID 4)
('VIP3-1', 10, 'AVAILABLE', 100000.00, -390, -110, 270, 120, 0, 'RECT', 4,
 'https://s.alicdn.com/@sc04/kf/H8c581ebf6cb24e8bbe86a609899189c0o/Modern-Luxury-4-people-Dining-Table-Chair-Set-Extendable-Kitchen-Restaurant-Tables-Rock-Plate-Chairs-Small-Marble-Dining-Room.jpg_300x300.jpg',
 'Phòng VIP 3 phong cách hiện đại, phục vụ hội họp doanh nghiệp.', NOW(), NOW()),
('VIP3-2', 10, 'AVAILABLE', 100000.00, -390, 100, 270, 120, 0, 'RECT', 4,
 'https://s.alicdn.com/@sc04/kf/H8c581ebf6cb24e8bbe86a609899189c0o/Modern-Luxury-4-people-Dining-Table-Chair-Set-Extendable-Kitchen-Restaurant-Tables-Rock-Plate-Chairs-Small-Marble-Dining-Room.jpg_300x300.jpg',
 'Bàn dài sang trọng, trang bị hệ thống âm thanh riêng.', NOW(), NOW()),

-- Area 5: Phòng VIP 4 (ID 5)
('VIP4-1', 8, 'AVAILABLE', 100000.00, 100, -200, 150, 150, 0, 'CIRCLE', 5,
 'https://assets.wfcdn.com/im/14684299/compr-r85/2280/228059320/Aryhanna+8+-+Person+Solid+Wood+Top+Pedestal+Dining+Set.jpg',
 'Bàn tròn lớn Phòng VIP 4, không gian trang nhã cổ điển.', NOW(), NOW()),
('VIP4-2', 8, 'AVAILABLE', 100000.00, 101, 30, 150, 150, 0, 'CIRCLE', 5,
 'https://assets.wfcdn.com/im/14684299/compr-r85/2280/228059320/Aryhanna+8+-+Person+Solid+Wood+Top+Pedestal+Dining+Set.jpg',
 'Phòng tiệc nhẹ nhàng, thích hợp cho các buổi ra mắt gia đình.', NOW(), NOW()),
('VIP4-3', 8, 'AVAILABLE', 100000.00, 500, -200, 150, 150, 0, 'CIRCLE', 5,
 'https://assets.wfcdn.com/im/14684299/compr-r85/2280/228059320/Aryhanna+8+-+Person+Solid+Wood+Top+Pedestal+Dining+Set.jpg',
 'Không gian VIP kín đáo, nội thất gỗ sang trọng.', NOW(), NOW()),
('VIP4-4', 8, 'AVAILABLE', 100000.00, 503, 30, 150, 150, 0, 'CIRCLE', 5,
 'https://assets.wfcdn.com/im/14684299/compr-r85/2280/228059320/Aryhanna+8+-+Person+Solid+Wood+Top+Pedestal+Dining+Set.jpg',
 'Bàn tiệc VIP khu vực yên tĩnh nhất nhà hàng.', NOW(), NOW()),

-- Area 6: Sân thượng (ID 6)
('T2-1', 6, 'AVAILABLE', 0.00, -280, -180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn sân thượng view thành phố lung linh về đêm.', NOW(), NOW()),
('T2-2', 6, 'AVAILABLE', 0.00, -80, -180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Không gian ngoài trời thoáng mát, đón gió tự nhiên.', NOW(), NOW()),
('T2-3', 6, 'AVAILABLE', 0.00, 855, 80, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Góc sân thượng riêng tư cho các buổi hẹn hò lãng mạn.', NOW(), NOW()),
('T2-4', 6, 'AVAILABLE', 0.00, 120, -180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn ngoài trời gần khu vực tiểu cảnh, không gian xanh.', NOW(), NOW()),
('T2-5', 6, 'AVAILABLE', 0.00, 520, 180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Khu vực Rooftop trung tâm, sôi động và náo nhiệt.', NOW(), NOW()),
('T2-6', 6, 'AVAILABLE', 0.00, 855, 330, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Vị trí ngắm hoàng hôn cực đẹp trên tầng thượng.', NOW(), NOW()),
('T2-7', 10, 'AVAILABLE', 0.00, -280, 0, 200, 90, 0, 'RECT', 6,
 'https://ak1.ostkcdn.com/images/products/is/images/direct/c5b3c26487fe7b03dadb2b2f4dbb5d0dff12e1c6/10-Person-Extendable-63%27%27-to-94.5%27%27-Dining-Set%2CRectangular-Sintered-Stone-Top%2CStainless-Steel-Legs%281-Table-10-Polo-Chairs%29.jpg?impolicy=medium',
 'Bàn tiệc lớn ngoài trời, thích hợp cho party công ty.', NOW(), NOW()),
('T2-8', 10, 'AVAILABLE', 0.00, 70, 0, 200, 90, 0, 'RECT', 6,
 'https://ak1.ostkcdn.com/images/products/is/images/direct/c5b3c26487fe7b03dadb2b2f4dbb5d0dff12e1c6/10-Person-Extendable-63%27%27-to-94.5%27%27-Dining-Set%2CRectangular-Sintered-Stone-Top%2CStainless-Steel-Legs%281-Table-10-Polo-Chairs%29.jpg?impolicy=medium',
 'Không gian tiệc tầng thượng, đẳng cấp và tự do.', NOW(), NOW()),
('T2-9', 6, 'AVAILABLE', 100000.00, 320, -180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn VIP sân thượng, phục vụ cocktail và đồ nướng.', NOW(), NOW()),
('T2-10', 6, 'AVAILABLE', 100000.00, 520, -180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Không gian cực chill dưới ánh đèn vàng lãng mạn.', NOW(), NOW()),
('T2-11', 10, 'AVAILABLE', 100000.00, 410, 0, 200, 90, 0, 'RECT', 6,
 'https://ak1.ostkcdn.com/images/products/is/images/direct/c5b3c26487fe7b03dadb2b2f4dbb5d0dff12e1c6/10-Person-Extendable-63%27%27-to-94.5%27%27-Dining-Set%2CRectangular-Sintered-Stone-Top%2CStainless-Steel-Legs%281-Table-10-Polo-Chairs%29.jpg?impolicy=medium',
 'Bàn dài VIP sân thượng khép kín khu riêng biệt.', NOW(), NOW()),
('T2-12', 6, 'AVAILABLE', 100000.00, -280, 180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Góc bàn view bao trọn toàn cảnh nhà hàng từ trên cao.', NOW(), NOW()),
('T2-13', 6, 'AVAILABLE', 100000.00, -80, 180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn sân thượng phong cách vintage, mộc mạc và gần gũi.', NOW(), NOW()),
('T2-14', 6, 'AVAILABLE', 100000.00, 320, 180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Khu vực Rooftop Bar sôi động với âm nhạc EDM nhẹ.', NOW(), NOW()),
('T2-15', 6, 'AVAILABLE', 100000.00, 120, 180, 90, 90, 0, 'SQUARE', 6,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn sân thượng cạnh quầy DJ, trải nghiệm không khí trẻ trung.', NOW(), NOW()),

-- Area 7: Ban công BBQ (ID 7)
('BBQ-1', 8, 'AVAILABLE', 100000.00, -501, -200, 150, 150, 0, 'CIRCLE', 7,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn tròn nướng BBQ ngoài trời, hệ thống hút khói hiện đại.', NOW(), NOW()),
('BBQ-2', 8, 'AVAILABLE', 100000.00, -183, 79, 150, 150, 0, 'CIRCLE', 7,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Không gian tiệc nướng BBQ lộng gió, view hồ bơi (giả tưởng).', NOW(), NOW()),
('BBQ-3', 8, 'AVAILABLE', 100000.00, -500, 80, 150, 150, 0, 'CIRCLE', 7,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Vị trí BBQ lý tưởng cho bữa tiệc tụ tập bạn bè cuối tuần.', NOW(), NOW()),
('BBQ-4', 8, 'AVAILABLE', 100000.00, -182, -200, 150, 150, 0, 'CIRCLE', 7,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Khu nướng BBQ gia đình, thân mật và thoáng đãng.', NOW(), NOW()),

-- Area 8: Phòng VIP 5 (ID 8)
('VIP5-1', 10, 'AVAILABLE', 500000.00, 0, 100, 359, 160, 0, 'RECT', 8,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Siêu phòng VIP 5, nội thất hoàng gia cao cấp nhất.', NOW(), NOW()),

-- Area 9: Phòng VIP 6 (ID 9)
('VIP6-1', 8, 'AVAILABLE', 200000.00, -350, 100, 240, 240, 0, 'CIRCLE', 9,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Phòng VIP 6 yên tĩnh, phục vụ các buổi họp trà đạo.', NOW(), NOW()),
('VIP6-2', 8, 'AVAILABLE', 200000.00, 20, 100, 240, 240, 0, 'CIRCLE', 9,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn tròn sang trọng, phục vụ menu đặc biệt thượng hạng.', NOW(), NOW()),

-- Area 10: Phòng VIP 7 (ID 10)
('VIP7-1', 8, 'AVAILABLE', 100000.00, 100, -200, 150, 150, 0, 'CIRCLE', 10,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Phòng VIP 7 phong cách Nhật Bản tối giản, tinh tế.', NOW(), NOW()),
('VIP7-2', 8, 'AVAILABLE', 100000.00, 101, 30, 150, 150, 0, 'CIRCLE', 10,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Không gian riêng tư nhẹ nhàng cho các cuộc trò chuyện sâu sắc.', NOW(), NOW()),
('VIP7-3', 8, 'AVAILABLE', 100000.00, 500, -200, 150, 150, 0, 'CIRCLE', 10,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Bàn VIP 7 khép kín, đội ngũ phục vụ riêng biệt.', NOW(), NOW()),
('VIP7-4', 8, 'AVAILABLE', 100000.00, 503, 30, 150, 150, 0, 'CIRCLE', 10,
 'https://plus.unsplash.com/premium_photo-1673108530231-e1e73e91d622?q=80&w=1000&auto=format&fit=crop',
 'Phòng VIP cuối dãy, không gian cực kỳ yên tĩnh và trang trọng.', NOW(), NOW());

INSERT INTO categories (name, slug, description, created_at, updated_at)
VALUES ('Món súp', 'mon-sup', 'Các món súp', NOW(), NOW()),
       ('Món khai vị', 'mon-khai-vi', 'Các món khai vị', NOW(), NOW()),
       ('Món gà', 'mon-ga', 'Các món từ gà', NOW(), NOW()),
       ('Món bò', 'mon-bo', 'Các món từ bò', NOW(), NOW()),
       ('Món heo', 'mon-heo', 'Các món từ heo', NOW(), NOW()),
       ('Món lẩu', 'mon-lau', 'Các món lẩu', NOW(), NOW()),
       ('Món rau', 'mon-rau', 'Các món rau', NOW(), NOW()),
       ('Món hải sản', 'mon-hai-san', 'Các món hải sản', NOW(), NOW()),
       ('Đồ uống', 'do-uong', 'Nước uống', NOW(), NOW()),
       ('Tráng miệng', 'trang-mieng', 'Món tráng miệng', NOW(), NOW());

INSERT INTO items (id, name, slug, description, image_url, price, price_after_discount, sold_count, status, category_id, created_at, updated_at)
VALUES
-- Category 1: Món súp (1-9)
(1, 'Súp hải sản', 'sup-hai-san', 'Súp hải sản thập cẩm', 'https://i.pinimg.com/1200x/c9/28/5f/c9285f6cea90c7d15589744e4785342b.jpg', 45000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),
(2, 'Súp măng tây', 'sup-mang-tay', 'Súp măng tây cua', 'https://i.pinimg.com/1200x/25/37/2f/25372fd3ef6b6a0f9c8075525ee1139e.jpg', 40000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),
(3, 'Súp bắp cua', 'sup-bap-cua', 'Súp bắp ngọt nấu cua', 'https://i.pinimg.com/1200x/62/67/81/62678184ece7e348cdc70e94ba7de0a7.jpg', 38000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),
(4, 'Súp nấm', 'sup-nam', 'Súp nấm đông cô', 'https://i.pinimg.com/1200x/10/21/7a/10217a55916c7426846a5ef8590cfab0.jpg', 35000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),
(5, 'Súp bào ngư', 'sup-bao-ngu', 'Súp bào ngư thượng hạng', 'https://i.pinimg.com/736x/12/d1/2a/12d12a8ecc5b9972dd0cd9aa3ac96a44.jpg', 150000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),
(6, 'Súp vi cá', 'sup-vi-ca', 'Súp vi cá mập', 'https://i.pinimg.com/1200x/fe/3d/a7/fe3da75d24af16a81a268b477b18702b.jpg', 250000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),
(7, 'Súp lươn', 'sup-luon', 'Súp lươn Nghệ An', 'https://i.pinimg.com/1200x/ca/ef/13/caef13c04721da62d476ada41d0e1cf2.jpg', 55000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),
(8, 'Súp gà', 'sup-ga', 'Súp gà xé phay', 'https://i.pinimg.com/736x/d4/dc/9d/d4dc9dcb7355d9bf7b12b094ef5d9e6d.jpg', 35000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),
(9, 'Súp tôm bí đỏ', 'sup-tom-bi-do', 'Súp kem bí đỏ tôm tươi', 'https://i.pinimg.com/1200x/ba/20/30/ba203044b185c6d10b838fe640c9eab9.jpg', 45000.00, NULL, 0, 'AVAILABLE', 1, NOW(), NOW()),

-- Category 2: Món khai vị (10-17)
(10, 'Nem rán', 'nem-ran', 'Nem rán truyền thống', 'https://i.pinimg.com/1200x/d1/98/7a/d1987add813a9784ae9a949e36c880e6.jpg', 50000.00, NULL, 0, 'AVAILABLE', 2, NOW(), NOW()),
(11, 'Phở cuốn', 'pho-cuon', 'Phở cuốn Hà Nội', 'https://i.pinimg.com/736x/9d/89/bf/9d89bf1de9faa62e1e5fc772cdd4340b.jpg', 60000.00, NULL, 0, 'AVAILABLE', 2, NOW(), NOW()),
(12, 'Gỏi ngó sen', 'goi-ngo-sen', 'Gỏi ngó sen tôm thịt', 'https://i.pinimg.com/1200x/f8/eb/b8/f8ebb880d3c815684aacb4ec14e73090.jpg', 75000.00, NULL, 0, 'AVAILABLE', 2, NOW(), NOW()),
(13, 'Khoai tây chiên', 'khoai-tay-chien', 'Khoai tây chiên bơ tỏi', 'https://i.pinimg.com/736x/cc/41/0c/cc410c5e28d49d1a8d7f940115f61aa0.jpg', 30000.00, NULL, 0, 'AVAILABLE', 2, NOW(), NOW()),
(14, 'Ngô chiên', 'ngo-chien', 'Ngô ngọt chiên bơ', 'https://i.pinimg.com/736x/92/50/b7/9250b7e4c48bf4fa8d5c941801ffc4a7.jpg', 35000.00, NULL, 0, 'AVAILABLE', 2, NOW(), NOW()),
(15, 'Nộm sứa', 'nom-sua', 'Nộm sứa biển giòn', 'https://i.pinimg.com/736x/84/5b/d1/845bd15d473b105c2b05aa23b6cd9e94.jpg', 65000.00, NULL, 0, 'AVAILABLE', 2, NOW(), NOW()),
(16, 'Gỏi xoài xanh tôm khô', 'goi-xoai-xanh-tom-kho', 'Gỏi xoài chua ngọt', 'https://i.pinimg.com/736x/84/1e/9a/841e9a160430a146489ce7a315597d18.jpg', 55000.00, NULL, 0, 'AVAILABLE', 2, NOW(), NOW()),
(17, 'Bánh gối', 'banh-goi', 'Bánh gối nhân thịt', 'https://i.pinimg.com/1200x/6c/04/48/6c0448c95271f24bc312b55e08a4168f.jpg', 45000.00, NULL, 0, 'AVAILABLE', 2, NOW(), NOW()),

-- Category 3: Món gà (18-22)
(18, 'Gà rang muối', 'ga-rang-muoi', 'Gà ta rang muối', 'https://i.pinimg.com/1200x/7f/83/4b/7f834be50eb86d6dce49a5dd8b046023.jpg', 120000.00, NULL, 0, 'AVAILABLE', 3, NOW(), NOW()),
(19, 'Gà luộc', 'ga-luoc', 'Gà ta luộc lá chanh', 'https://i.pinimg.com/1200x/98/92/bf/9892bf62bf6d1a7532c8932cca966817.jpg', 150000.00, NULL, 0, 'AVAILABLE', 3, NOW(), NOW()),
(20, 'Gà nướng mật ong', 'ga-nuong-mat-ong', 'Gà nướng mật rừng', 'https://i.pinimg.com/1200x/40/e1/a4/40e1a4be26f1d292232f2efcd644c3ac.jpg', 180000.00, NULL, 0, 'AVAILABLE', 3, NOW(), NOW()),
(21, 'Cánh gà chiên bơ', 'canh-ga-chien-bo', 'Cánh gà chiên bơ tỏi', 'https://i.pinimg.com/1200x/8c/86/ac/8c86acc49c0ee90108340b25f7f75bee.jpg', 85000.00, NULL, 0, 'AVAILABLE', 3, NOW(), NOW()),
(22, 'Gà xào sả ớt', 'ga-xao-sa-ot', 'Gà ta xào sả ớt', 'https://i.pinimg.com/1200x/e9/9d/a0/e99da014eb1e1ab23f28f1216beac101.jpg', 110000.00, NULL, 0, 'AVAILABLE', 3, NOW(), NOW()),

-- Category 4: Món bò (23-26)
(23, 'Bò xào cần tỏi', 'bo-xao-can-toi', 'Bò thăn xào cần tỏi', 'https://i.pinimg.com/736x/3f/88/9c/3f889c6c40ddc0b23f2e16a433247488.jpg', 125000.00, NULL, 0, 'AVAILABLE', 4, NOW(), NOW()),
(24, 'Bò kho', 'bo-kho', 'Bò kho bánh mì', 'https://i.pinimg.com/1200x/ef/e2/25/efe225d8273ef8d329083032f2eb42ac.jpg', 85000.00, NULL, 0, 'AVAILABLE', 4, NOW(), NOW()),
(25, 'Bò sốt vang', 'bo-sot-vang', 'Bò sốt vang tiêu đen', 'https://i.pinimg.com/736x/0f/b2/1e/0fb21e521317d6368ab89e5380bf4e4c.jpg', 95000.00, NULL, 0, 'AVAILABLE', 4, NOW(), NOW()),
(26, 'Bò tái chanh', 'bo-tai-chanh', 'Bò phi lê tái chanh', 'https://i.pinimg.com/736x/e6/a0/b7/e6a0b70c5421873a726cd6df5a6a701b.jpg', 115000.00, NULL, 0, 'AVAILABLE', 4, NOW(), NOW()),

-- Category 5: Món heo (27-31)
(27, 'Bò lúc lắc', 'bo-luc-lac', 'Bò lúc lắc sốt tiêu đen khoai tây chiên', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 145000.00, NULL, 0, 'AVAILABLE', 5, NOW(), NOW()),
(28, 'Heo quay', 'heo-quay', 'Thịt heo quay da giòn', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 130000.00, NULL, 0, 'AVAILABLE', 5, NOW(), NOW()),
(29, 'Sườn xào chua ngọt', 'suon-xao-chua-ngot', 'Sườn non xào chua ngọt đậm đà', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 110000.00, NULL, 0, 'AVAILABLE', 5, NOW(), NOW()),
(30, 'Ba chỉ rang cháy cạnh', 'ba-chi-rang-chay-canh', 'Ba chỉ heo rang cháy cạnh giòn thơm', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 85000.00, NULL, 0, 'AVAILABLE', 5, NOW(), NOW()),
(31, 'Thịt kho tàu', 'thit-kho-tau', 'Thịt kho tàu nước dừa trứng cút', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 90000.00, NULL, 0, 'AVAILABLE', 5, NOW(), NOW()),

-- Category 6: Món lẩu (32-35)
(32, 'Lẩu thái', 'lau-thai', 'Lẩu thái hải sản chua cay thơm nồng', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 250000.00, NULL, 0, 'AVAILABLE', 6, NOW(), NOW()),
(33, 'Lẩu gà lá é', 'lau-ga-la-e', 'Lẩu gà ta nấu lá é đặc sản Phú Yên', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 230000.00, NULL, 0, 'AVAILABLE', 6, NOW(), NOW()),
(34, 'Lẩu riêu cua bắp bò', 'lau-rieu-cua-bap-bo', 'Lẩu riêu cua đồng tươi bắp bò hoa', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 260000.00, NULL, 0, 'AVAILABLE', 6, NOW(), NOW()),
(35, 'Lẩu hải sản', 'lau-hai-san', 'Lẩu hải sản thập cẩm tôm mực nghêu', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 280000.00, NULL, 0, 'AVAILABLE', 6, NOW(), NOW()),

-- Category 7: Món rau (36-41)
(36, 'Rau muống xào tỏi', 'rau-muong-xao-toi', 'Rau muống non xào tỏi thơm giòn', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 35000.00, NULL, 0, 'AVAILABLE', 7, NOW(), NOW()),
(37, 'Cải thìa xốt dầu hào', 'cai-thia-xot-dau-hao', 'Cải thìa thanh ngọt xốt dầu hào nấm hương', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 40000.00, NULL, 0, 'AVAILABLE', 7, NOW(), NOW()),
(38, 'Nộm rau muống tép đồng', 'nom-rau-muong-tep-dong', 'Nộm rau muống giòn chua ngọt tép rang', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 45000.00, NULL, 0, 'AVAILABLE', 7, NOW(), NOW()),
(39, 'Rau củ luộc kho quẹt', 'rau-cu-luoc-kho-quet', 'Rau củ luộc thập cẩm chấm kho quẹt tôm thịt', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 55000.00, NULL, 0, 'AVAILABLE', 7, NOW(), NOW()),
(40, 'Salad Nga', 'salad-nga', 'Salad rau củ quả sốt mayonnaise béo thơm', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 50000.00, NULL, 0, 'AVAILABLE', 7, NOW(), NOW()),
(41, 'Rau lang xào tỏi', 'rau-lang-xao-toi', 'Rau lang tươi non xào tỏi thơm ngon', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 35000.00, NULL, 0, 'AVAILABLE', 7, NOW(), NOW()),

-- Category 8: Món hải sản (42-47)
(42, 'Cua hấp bia', 'cua-hap-bia', 'Cua biển Cà Mau hấp bia sả thơm lừng', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 350000.00, NULL, 0, 'AVAILABLE', 8, NOW(), NOW()),
(43, 'Mực chiên giòn', 'muc-chien-gion', 'Mực ống tươi cắt khoanh chiên giòn rụm', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 120000.00, NULL, 0, 'AVAILABLE', 8, NOW(), NOW()),
(44, 'Tôm sú nướng muối ớt', 'tom-su-nuong-muoi-ot', 'Tôm sú tươi nướng muối ớt cay đậm đà', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 150000.00, NULL, 0, 'AVAILABLE', 8, NOW(), NOW()),
(45, 'Hàu nướng mỡ hành', 'hau-nuong-mo-hanh', 'Hàu sữa tươi nướng mỡ hành đậu phộng giòn', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 95000.00, NULL, 0, 'AVAILABLE', 8, NOW(), NOW()),
(46, 'Cá hồi áp chảo sốt chanh leo', 'ca-hoi-ap-chao-sot-chanh-leo', 'Phi lê cá hồi Nauy áp chảo kèm sốt chanh leo chua ngọt', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 185000.00, NULL, 0, 'AVAILABLE', 8, NOW(), NOW()),
(47, 'Bạch tuộc nướng sa tế', 'bach-tuoc-nuong-sa-te', 'Bạch tuộc nướng sa tế cay nồng giòn sần sật', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 135000.00, NULL, 0, 'AVAILABLE', 8, NOW(), NOW()),

-- Category 9: Đồ uống (48-54)
(48, 'Bia Hà Nội', 'bia-ha-noi', 'Bia lon Hà Nội mát lạnh', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 22000.00, NULL, 0, 'AVAILABLE', 9, NOW(), NOW()),
(49, 'Bia Sài Gòn', 'bia-sai-gon', 'Bia Sài Gòn Special ướp lạnh', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 22000.00, NULL, 0, 'AVAILABLE', 9, NOW(), NOW()),
(50, 'Nước suối Aquafina', 'nuoc-suoi-aquafina', 'Nước tinh khiết chai 500ml', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 10000.00, NULL, 0, 'AVAILABLE', 9, NOW(), NOW()),
(51, 'Nước ngọt Pepsi', 'nuoc-ngot-pepsi', 'Pepsi lon mát lạnh sảng khoái', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 15000.00, NULL, 0, 'AVAILABLE', 9, NOW(), NOW()),
(52, 'Nước ngọt Coca Cola', 'nuoc-ngot-coca-cola', 'Coca Cola chai mát lạnh', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 15000.00, NULL, 0, 'AVAILABLE', 9, NOW(), NOW()),
(53, 'Nước ngọt Mirinda', 'nuoc-ngot-mirinda', 'Mirinda hương cam thơm ngọt', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 15000.00, NULL, 0, 'AVAILABLE', 9, NOW(), NOW()),
(54, 'Rượu Macallan 12', 'ruou-macallan-12', 'Rượu ngoại Macallan 12 thượng hạng nguyên chai', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 2500000.00, NULL, 0, 'AVAILABLE', 9, NOW(), NOW()),

-- Category 10: Tráng miệng (55-60)
(55, 'Bánh flan caramel', 'banh-flan-caramel', 'Bánh flan béo ngậy sốt cà phê caramel ngọt dịu', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 25000.00, NULL, 0, 'AVAILABLE', 10, NOW(), NOW()),
(56, 'Chè khúc bạch', 'che-khuc-bach', 'Chè khúc bạch thanh mát hạnh nhân thơm bùi', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 30000.00, NULL, 0, 'AVAILABLE', 10, NOW(), NOW()),
(57, 'Chè thái sầu riêng', 'che-thai-sau-rieng', 'Chè thái hoa quả sầu riêng thơm béo ngậy', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 35000.00, NULL, 0, 'AVAILABLE', 10, NOW(), NOW()),
(58, 'Hoa quả dĩa theo mùa', 'hoa-qua-dia-theo-mua', 'Đĩa trái cây tươi mát các loại theo mùa', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 45000.00, NULL, 0, 'AVAILABLE', 10, NOW(), NOW()),
(59, 'Rau câu sơn thủy', 'rau-cau-son-thuy', 'Thạch rau câu sơn thủy thanh mát ngọt lành', 'https://i.pinimg.com/736x/48/4d/52/484d528ef3ea81fa4d4ad7aa7550ca22.jpg', 25000.00, NULL, 0, 'AVAILABLE', 10, NOW(), NOW()),
(60, 'Kem bơ dừa nướng', 'kem-bo-dua-nuong', 'Kem bơ dừa béo mịn thơm lừng vụn dừa nướng', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 35000.00, NULL, 0, 'AVAILABLE', 10, NOW(), NOW());




INSERT INTO combos (name, slug, description, image_url, price, price_after_discount, sold_count, status, created_at, updated_at)
VALUES
    ('Combo Tiệc Lẩu Riêu', 'combo-tiec-lau-rieu', 'Lẩu riêu cua bắp bò + Nem rán + Rau lang xào tỏi + 2 Bia Hà Nội', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 471000.00, 429000.00, 15, 'AVAILABLE', NOW(), NOW()),
    ('Combo Gà Ngon Hấp Dẫn', 'combo-ga-ngon-hap-dan', 'Gà rang muối + Phở cuốn + Nộm rau muống + 2 Pepsi', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 245000.00, 219000.00, 28, 'AVAILABLE', NOW(), NOW()),
    ('Combo Nhậu Hải Sản', 'combo-nhau-hai-san', 'Cua hấp bia + Bạch tuộc nướng sa tế + 4 Bia Sài Gòn', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 673000.00, 599000.00, 10, 'AVAILABLE', NOW(), NOW()),
    ('Combo Bò Cao Cấp', 'combo-bo-cao-cap', 'Bò lúc lắc + Súp bào ngư + Rượu Macallan 12', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 2795000.00, 2649000.00, 5, 'AVAILABLE', NOW(), NOW()),
    ('Combo Tráng Miệng Chill', 'combo-trang-mieng-chill', 'Chè thái + Kem bơ + 2 Mirinda', 'https://i.pinimg.com/736x/2e/8c/86/2e8c8656396c2b471d4d8eef93585908.jpg', 110000.00, 99000.00, 45, 'AVAILABLE', NOW(), NOW());

INSERT INTO combo_items (combo_id, item_id, quantity, created_at, updated_at)
VALUES
-- Combo 1: Lẩu riêu (34) + Nem rán (10) + Rau lang (41) + 2 Bia HN (48)
(1, 34, 1, NOW(), NOW()),
(1, 10, 1, NOW(), NOW()),
(1, 41, 1, NOW(), NOW()),
(1, 48, 2, NOW(), NOW()),

-- Combo 2: Gà rang muối (18) + Phở cuốn (11) + Nộm rau muống (38) + 2 Pepsi (51)
(2, 18, 1, NOW(), NOW()),
(2, 11, 1, NOW(), NOW()),
(2, 38, 1, NOW(), NOW()),
(2, 51, 2, NOW(), NOW()),

-- Combo 3: Cua hấp bia (42) + Bạch tuộc nướng sa tế (47) + 4 Bia SG (49)
(3, 42, 1, NOW(), NOW()),
(3, 47, 1, NOW(), NOW()),
(3, 49, 4, NOW(), NOW()),

-- Combo 4: Bò lúc lắc (27) + Súp bào ngư (5) + Rượu Macallan 12 (54)
(4, 27, 1, NOW(), NOW()),
(4, 5, 1, NOW(), NOW()),
(4, 54, 1, NOW(), NOW()),

-- Combo 5: Chè thái (57) + Kem bơ (60) + 2 Mirinda (53)
(5, 57, 1, NOW(), NOW()),
(5, 60, 1, NOW(), NOW()),
(5, 53, 2, NOW(), NOW());

INSERT INTO vouchers (id, name, code, description, type, discount_value, max_discount_value, min_value, points_required, created_at, updated_at)
VALUES
    (1, 'Giảm 10%', 'CD10', 'Giảm 10% tổng bill', 'PERCENTAGE', 10.00, 50000.00, NULL, NULL, NOW(), NOW()),
    (2, 'Giảm 50K', 'CD50K', 'Giảm thẳng 50.000đ', 'FIXED_AMOUNT', 50000.00, NULL, 70000.00, NULL, NOW(), NOW()),
    (3, 'Giảm 10% - 2', 'CD10-2', 'Giảm 10% (đợt 2) - name trùng vẫn OK', 'PERCENTAGE', 10.00, 30000.00, NULL, NULL, NOW(), NOW()),
    (4, 'Voucher Điểm Thưởng 50K', 'REWARD50', 'Đổi 50 điểm lấy voucher giảm 50.000 VNĐ', 'FIXED_AMOUNT', 50000.00, 50000.00, 70000.00, 50, NOW(), NOW()),
    (5, 'Voucher Điểm Thưởng 100K', 'REWARD100', 'Đổi 100 điểm lấy voucher giảm 100.000 VNĐ', 'FIXED_AMOUNT', 100000.00, 100000.00, 120000.00, 100, NOW(), NOW()),
    (6, 'Voucher Điểm Thưởng 200K', 'REWARD200', 'Đổi 200 điểm lấy voucher giảm 200.000 VNĐ', 'FIXED_AMOUNT', 200000.00, 200000.00, 220000.00, 200, NOW(), NOW()),
    (7, 'Voucher Điểm Thưởng 500K', 'REWARD500', 'Đổi 500 điểm lấy voucher giảm 500.000 VNĐ', 'FIXED_AMOUNT', 500000.00, 500000.00, 520000.00, 500, NOW(), NOW());


INSERT INTO users (id, username, password, avatar_url, email, first_name, last_name, date_of_birth, gender, status, phone, reward_points, created_at, updated_at)
VALUES
(1, 'johndoe', '$2a$10$s3go5e.GYivSMmrJXG6jceddjfSAbg6O832Sip8XIVNRRLIjXNP6G', 'https://i.pinimg.com/736x/49/15/d1/4915d11ef3a6a8e2e1245fa46c16a8a2.jpg', 'johndoe@gmail.com', 'John', 'Doe', '2002-05-10', 'MALE', 'ACTIVE', '0912345678', 5000, NOW(), NOW()),
(2, 'alice', '$2a$10$EeSehs49igNMz6Vuk69cDuaAGHFrWSjeOvMmNkaAr6ZwyZtltKStS', 'https://i.pinimg.com/736x/07/16/a8/0716a8e465a5a2e9a8e78f37c0b8cd9c.jpg', '0901dattran@gmail.com', 'Alice', 'Nguyen', '2003-05-14', 'FEMALE', 'ACTIVE', '0913443344', 5000, NOW(), NOW()),
(3, 'johncena', '$2a$10$llGgE5VlZzM0.pCzbOLGWev.cqdovrjSsq0lGM87wo0FVgATXsh12', 'https://i.pinimg.com/736x/90/fd/19/90fd1986c9cff08c20eacbaf7045dd9c.jpg', 'johncena@gmail.com', 'John', 'Cena', '1998-05-14', 'MALE', 'ACTIVE', '0913324344', 0, NOW(), NOW()),
(4, 'minhanh', '$2a$10$f8K0p/rAvE9SrsZcahthQuKA79pIAqGt9APO14f3.czxnCPp9q6Iu', NULL, 'minhanh@crowndine.local', 'Minh', 'Anh', '2001-03-12', 'FEMALE', 'ACTIVE', '0901100001', 0, NOW(), NOW()),
(5, 'thutrang', '$2a$10$OEYH9he8BWJRnCytYVcmB.W4lk6WlwAHnAgVf9aQHZch5gJ.HUiAu', NULL, 'thutrang@crowndine.local', 'Thu', 'Trang', '2000-07-24', 'FEMALE', 'ACTIVE', '0901100002', 0, NOW(), NOW()),
(6, 'quochuy', '$2a$10$2XGuYngpcuowaqhZbvTLGuhlNg5n3sn9GdbzQGyWcMvKm3G/FOZbS', NULL, 'quochuy@crowndine.local', 'Quoc', 'Huy', '1999-11-08', 'MALE', 'ACTIVE', '0901100003', 0, NOW(), NOW()),
(7, 'ngocmai', '$2a$10$gYToj5teNH/bDuMaboswr.RCWyw3mnhxVw7fXYTRDVoeh/qy5eVdm', NULL, 'ngocmai@crowndine.local', 'Ngoc', 'Mai', '2002-01-19', 'FEMALE', 'ACTIVE', '0901100004', 0, NOW(), NOW()),
(8, 'thanhtung', '$2a$10$XDav3qdVlNkr58OGZZVm7uGdQs4D9kAeqw555rq0lo6q6NG7EB87C', NULL, 'thanhtung@crowndine.local', 'Thanh', 'Tung', '1998-09-03', 'MALE', 'ACTIVE', '0901100005', 0, NOW(), NOW()),
(9, 'baovy', '$2a$10$2/BYSYBiyru0TusrcILpHejPJXShhDUbLe4AhvAvX2Loy28hZuZzq', NULL, 'baovy@crowndine.local', 'Bao', 'Vy', '2003-06-15', 'FEMALE', 'ACTIVE', '0901100006', 0, NOW(), NOW()),
(10, 'hoangyen', '$2a$10$k0Pe70Q6Ng7btefKDxPI9.g6dS5L/078.eb9ykojULQHrhj6QrEaG', NULL, 'hoangyen@crowndine.local', 'Hoang', 'Yen', '2001-12-02', 'FEMALE', 'ACTIVE', '0901100007', 0, NOW(), NOW()),
(11, 'ductri', '$2a$10$RQhy/.FDwnIHKS7vUx6gBeFviqoEEfPe8dAQowIlwhBwUoanbtKJ.', NULL, 'ductri@crowndine.local', 'Duc', 'Tri', '1997-04-27', 'MALE', 'ACTIVE', '0901100008', 0, NOW(), NOW()),
(12, 'kimngan', '$2a$10$/lnvxAHZOhbb0wjfK40LYeEyd.crr3ikTYemydilZW6JlTyDdOp9e', NULL, 'kimngan@crowndine.local', 'Kim', 'Ngan', '2004-08-14', 'FEMALE', 'ACTIVE', '0901100009', 0, NOW(), NOW()),
(13, 'annhi', '$2a$10$V53.Yc2EmYI0byjNWMYgoOAHUCRSQrQ0D5gbwu8Kau.E8j9ajjBGG', NULL, 'annhi@crowndine.local', 'An', 'Nhi', '2002-10-09', 'FEMALE', 'INACTIVE', '0901100010', 0, NOW(), NOW()),
(14, 'nguyenkhoa', '$2a$10$n8Pl2zirf/Gca5l8aTKQbuEGfol/MzgtbtXXInKkINtYbn37OX0v6', NULL, 'nguyenkhoa.staff@crowndine.local', 'Nguyen', 'Khoa', '1995-05-17', 'MALE', 'ACTIVE', '0902200001', 5000, NOW(), NOW()),
(15, 'thuyduong', '$2a$10$qPuhubmfya.dzZPjN7n8C.e7XkwhZEIs2NWc9duaRhJehMeJxbyT2', NULL, 'thuyduong.staff@crowndine.local', 'Thuy', 'Duong', '1996-02-11', 'FEMALE', 'ACTIVE', '0902200002', 5000, NOW(), NOW()),
(16, 'hoanglong', '$2a$10$xU6pg09xUTnIaiUY3EAGAO7DArkh0gGi7VXFIH7jomraEsOo4fp5q', NULL, 'hoanglong.staff@crowndine.local', 'Hoang', 'Long', '1997-09-22', 'MALE', 'ACTIVE', '0902200003', 5000, NOW(), NOW()),
(17, 'mylinh', '$2a$10$ER.uoSiYqEtSX.QmliHXHOMBFrCIGwYp6cgUxcgdAq7kSVgfZPohW', NULL, 'mylinh.staff@crowndine.local', 'My', 'Linh', '1998-01-30', 'FEMALE', 'ACTIVE', '0902200004', 5000, NOW(), NOW()),
(18, 'quanghuy', '$2a$10$sCOOYR47CI8tKPz0hGRceusjfeNYVcxnRnTcKsWikFPmLPy0rYWXG', NULL, 'quanghuy.staff@crowndine.local', 'Quang', 'Huy', '1999-07-06', 'MALE', 'ACTIVE', '0902200005', 5000, NOW(), NOW()),
(19, 'diemmy', '$2a$10$ymkp.wkR2qE8V9nlgYNKQe6xfFEpvlNhO3hwhryYnsqii0pqAaMpC', NULL, 'diemmy.staff@crowndine.local', 'Diem', 'My', '2000-03-28', 'FEMALE', 'ACTIVE', '0902200006', 5000, NOW(), NOW()),
(20, 'phuocan', '$2a$10$DFYEE5OIHU3QWgGaiWXt7OTV6zRtY.GDeq4zTnx3HtZdAeCK0KsCe', NULL, 'phuocan.staff@crowndine.local', 'Phuoc', 'An', '2001-11-13', 'MALE', 'ACTIVE', '0902200007', 5000, NOW(), NOW()),
(21, 'tramlam', '$2a$10$YAuhlJBlUbowaD.GhtuG3u962klwTxWWcKLthL5Xk868LXyHPepty', NULL, 'tramlam.staff@crowndine.local', 'Tram', 'Lam', '2003-04-16', 'FEMALE', 'ACTIVE', '0902200008', 5000, NOW(), NOW()),
(22, 'anhkiet', '$2a$10$1g8VX1G3WNLT.iei7k2.IeWfAQcajgeWqfL95.4Y4KO8AXMONbzW2', NULL, 'anhkiet.staff@crowndine.local', 'Anh', 'Kiet', '2005-08-21', 'MALE', 'ACTIVE', '0902200009', 5000, NOW(), NOW()),
(23, 'thanhha', '$2a$10$dZr/DYrilsusmew//sI45OQp0/CS.M10j82gkgVa8TdHMFTGhoKqq', NULL, 'thanhha.staff@crowndine.local', 'Thanh', 'Ha', '2006-12-05', 'FEMALE', 'INACTIVE', '0902200010', 5000, NOW(), NOW());


INSERT INTO user_roles (user_id, role_id)
VALUES (1, 1),
       (1, 2),
       (1, 3),
       (2, 2),
       (2, 3),
       (3, 3);

INSERT INTO user_roles (user_id, role_id)
VALUES (4, 3),
       (5, 3),
       (6, 3),
       (7, 3),
       (8, 3),
       (9, 3),
       (10, 3),
       (11, 3),
       (12, 3),
       (13, 3),
       (14, 2),
       (15, 2),
       (16, 2),
       (17, 2),
       (18, 2),
       (19, 2),
       (20, 2),
       (21, 2),
       (22, 2),
       (23, 2);

INSERT INTO user_vouchers (customer_id, voucher_id, usage_count, usage_limit, assigned_at)
VALUES (2, 1, 0, 1, NOW()),
       (2, 2, 0, 1, NOW()),
       (3, 1, 0, 1, NOW());


-- STANDALONE ORDERS
INSERT INTO orders (id, code, user_id, reservation_id, restaurant_table_id, voucher_id, total_price, discount_price,
                    final_price, status, created_at, updated_at)
VALUES (1, 'ORD-001', 1, NULL, 1, NULL, 328000.00, 0, 328000.00, 'COMPLETED', NOW(), NOW()),
       (2, 'ORD-002', 2, NULL, 2, NULL, 238000.00, 0, 238000.00, 'COMPLETED', NOW(), NOW());

-- DỮ LIỆU SEED CHO DASHBOARD: HÔM NAY, HÔM QUA, 7 NGÀY QUA, THÁNG NÀY, THÁNG TRƯỚC
-- Lưu ý: Sử dụng CURDATE() và DATE_SUB() để dữ liệu luôn phản ánh đúng theo thời điểm hiện tại khi chạy script.

-- 1. HÔM NAY (TODAY): Các mốc thời gian từ 7g-22g
INSERT INTO orders (id, code, user_id, reservation_id, restaurant_table_id, voucher_id, total_price, discount_price,
                    final_price, status, created_at, updated_at)
VALUES (3, 'ORD-003', 2, NULL, 1, NULL, 150000.00, 0, 150000.00, 'COMPLETED', CONCAT(CURDATE(), ' 07:30:00'),
        CONCAT(CURDATE(), ' 07:30:00')),
       (4, 'ORD-004', 3, NULL, 2, NULL, 280000.00, 0, 280000.00, 'COMPLETED', CONCAT(CURDATE(), ' 09:15:00'),
        CONCAT(CURDATE(), ' 09:15:00')),
       (5, 'ORD-005', 1, NULL, 3, NULL, 550000.00, 0, 550000.00, 'COMPLETED', CONCAT(CURDATE(), ' 12:45:00'),
        CONCAT(CURDATE(), ' 12:45:00')),
       (6, 'ORD-006', 2, NULL, 4, NULL, 320000.00, 0, 320000.00, 'COMPLETED', CONCAT(CURDATE(), ' 15:20:00'),
        CONCAT(CURDATE(), ' 15:20:00')),
       (7, 'ORD-007', 3, NULL, 1, NULL, 850000.00, 0, 850000.00, 'COMPLETED', CONCAT(CURDATE(), ' 18:50:00'),
        CONCAT(CURDATE(), ' 18:50:00')),
       (8, 'ORD-008', 1, NULL, 2, NULL, 620000.00, 0, 620000.00, 'COMPLETED', CONCAT(CURDATE(), ' 21:10:00'),
        CONCAT(CURDATE(), ' 21:10:00')),
       (9, 'ORD-009', 2, NULL, 3, NULL, 400000.00, 0, 400000.00, 'COMPLETED', CONCAT(CURDATE(), ' 19:30:00'),
        CONCAT(CURDATE(), ' 19:30:00'));

-- 2. HÔM QUA (YESTERDAY): Các mốc thời gian từ 8g-22g
INSERT INTO orders (id, code, user_id, reservation_id, restaurant_table_id, voucher_id, total_price, discount_price,
                    final_price, status, created_at, updated_at)
VALUES (10, 'ORD-010', 1, NULL, 1, NULL, 200000.00, 0, 200000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 08:00:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 08:00:00')),
       (11, 'ORD-011', 2, NULL, 2, NULL, 420000.00, 0, 420000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 11:30:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 11:30:00')),
       (12, 'ORD-012', 3, NULL, 3, NULL, 350000.00, 0, 350000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 14:00:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 14:00:00')),
       (13, 'ORD-013', 1, NULL, 4, NULL, 620000.00, 0, 620000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 17:00:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 17:00:00')),
       (14, 'ORD-014', 2, NULL, 1, NULL, 950000.00, 0, 950000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 19:30:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 19:30:00')),
       (15, 'ORD-015', 3, NULL, 2, NULL, 580000.00, 0, 580000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 21:45:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 21:45:00'));

-- 3. 7 NGÀY QUA (LAST 7 DAYS - Không tính hôm nay và hôm qua)
INSERT INTO orders (id, code, user_id, reservation_id, restaurant_table_id, voucher_id, total_price, discount_price,
                    final_price, status, created_at, updated_at)
VALUES (16, 'ORD-016', 1, NULL, 1, NULL, 1200000.00, 0, 1200000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:00:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:00:00')),
       (17, 'ORD-017', 2, NULL, 2, NULL, 1500000.00, 0, 1500000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 13:00:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 13:00:00')),
       (18, 'ORD-018', 3, NULL, 3, NULL, 900000.00, 0, 900000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 4 DAY), ' 18:00:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 4 DAY), ' 18:00:00')),
       (19, 'ORD-019', 1, NULL, 4, NULL, 1800000.00, 0, 1800000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 5 DAY), ' 19:00:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 5 DAY), ' 19:00:00')),
       (20, 'ORD-020', 2, NULL, 1, NULL, 1100000.00, 0, 1100000.00, 'COMPLETED',
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 6 DAY), ' 12:00:00'),
        CONCAT(DATE_SUB(CURDATE(), INTERVAL 6 DAY), ' 12:00:00'));

-- 4. THÁNG NÀY (THIS MONTH - Các ngày đầu tháng)
INSERT INTO orders (id, code, user_id, reservation_id, restaurant_table_id, voucher_id, total_price, discount_price,
                    final_price, status, created_at, updated_at)
VALUES (21, 'ORD-021', 1, NULL, 2, NULL, 2500000.00, 0, 2500000.00, 'COMPLETED',
        CONCAT(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) + INTERVAL 1 DAY, ' 12:00:00'),
        CONCAT(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) + INTERVAL 1 DAY, ' 12:00:00')),
       (22, 'ORD-022', 3, NULL, 3, NULL, 3200000.00, 0, 3200000.00, 'COMPLETED',
        CONCAT(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) + INTERVAL 5 DAY, ' 18:00:00'),
        CONCAT(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) + INTERVAL 5 DAY, ' 18:00:00'));

-- 5. THÁNG TRƯỚC (LAST MONTH): Một vài ngày cố định
INSERT INTO orders (id, code, user_id, reservation_id, restaurant_table_id, voucher_id, total_price, discount_price,
                    final_price, status, created_at, updated_at)
VALUES (23, 'ORD-023', 1, NULL, 1, NULL, 1000000.00, 0, 1000000.00, 'COMPLETED',
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 25 DAY), ' 12:00:00'),
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 25 DAY), ' 12:00:00')),
       (24, 'ORD-024', 2, NULL, 2, NULL, 1200000.00, 0, 1200000.00, 'COMPLETED',
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 15 DAY), ' 13:00:00'),
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 15 DAY), ' 13:00:00')),
       (25, 'ORD-025', 3, NULL, 3, NULL, 1800000.00, 0, 1800000.00, 'COMPLETED',
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 10 DAY), ' 18:00:00'),
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 10 DAY), ' 18:00:00')),
       (26, 'ORD-026', 1, NULL, 4, NULL, 2200000.00, 0, 2200000.00, 'COMPLETED',
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 5 DAY), ' 19:00:00'),
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 5 DAY), ' 19:00:00')),
       (27, 'ORD-027', 2, NULL, 1, NULL, 1500000.00, 0, 1500000.00, 'COMPLETED',
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 1 DAY), ' 20:00:00'),
        CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 1 DAY), ' 20:00:00'));

INSERT INTO order_details
(order_id, item_id, combo_id, quantity, total_price, note, created_at, updated_at)
VALUES
-- Order 1: gọi món lẻ
(1, 6, NULL, 1, 229000.00, 'Ít cay', NOW(), NOW()),
(1, 7, NULL, 1, 39000.00, NULL, NOW(), NOW()),
(1, 9, NULL, 1, 35000.00, 'Ít đá', NOW(), NOW()),
(1, 11, NULL, 1, 25000.00, NULL, NOW(), NOW()),

-- Order 2: gọi combo
(2, NULL, 4, 1, 219000.00, 'Không hành', NOW(), NOW()),
-- thêm 1 coca lẻ
(2, 10, NULL, 1, 19000.00, NULL, NOW(), NOW());

-- DATA CHO TOP PRODUCTS (Order Details cho các đơn dashboard)
INSERT INTO order_details (order_id, item_id, combo_id, quantity, total_price, created_at, updated_at)
VALUES
-- Hôm nay (Orders 3-9)
(3, 4, NULL, 1, 150000.00, CONCAT(CURDATE(), ' 07:30:00'), CONCAT(CURDATE(), ' 07:30:00')), -- Bò bít tết
(4, 3, NULL, 2, 280000.00, CONCAT(CURDATE(), ' 09:15:00'), CONCAT(CURDATE(), ' 09:15:00')), -- Gà chiên mắm
(5, 6, NULL, 1, 550000.00, CONCAT(CURDATE(), ' 12:45:00'), CONCAT(CURDATE(), ' 12:45:00')), -- Lẩu thái
(6, 8, NULL, 2, 320000.00, CONCAT(CURDATE(), ' 15:20:00'), CONCAT(CURDATE(), ' 15:20:00')), -- Tôm hấp
(7, 1, NULL, 1, 35000.00, CONCAT(CURDATE(), ' 18:50:00'), CONCAT(CURDATE(), ' 18:50:00')),  -- Súp cua (MỚI)
(7, 2, NULL, 1, 45000.00, CONCAT(CURDATE(), ' 18:50:00'), CONCAT(CURDATE(), ' 18:50:00')),  -- Salad (MỚI)
(7, 9, NULL, 2, 70000.00, CONCAT(CURDATE(), ' 18:50:00'), CONCAT(CURDATE(), ' 18:50:00')),  -- Trà đào (MỚI)
(8, 3, NULL, 5, 620000.00, CONCAT(CURDATE(), ' 21:10:00'), CONCAT(CURDATE(), ' 21:10:00')), -- Gà chiên mắm
(9, 6, NULL, 2, 400000.00, CONCAT(CURDATE(), ' 19:30:00'), CONCAT(CURDATE(), ' 19:30:00')), -- Lẩu thái

-- Hôm qua (Orders 10-15)
(10, 4, NULL, 2, 200000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 08:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 08:00:00')),
(11, 3, NULL, 4, 420000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 11:30:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 11:30:00')),
(12, 6, NULL, 1, 350000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 14:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 14:00:00')),
(13, 8, NULL, 4, 620000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 17:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 17:00:00')),
(14, 5, NULL, 3, 300000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 19:30:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 19:30:00')),                                 -- Heo quay (MỚI)
(15, 7, NULL, 5, 195000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 21:45:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 21:45:00')),                                 -- Rau muống (MỚI)
(15, 10, NULL, 5, 95000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 21:45:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 21:45:00')),                                 -- Coca (MỚI)

-- 7 ngày qua (Orders 16-20)
(16, 4, NULL, 3, 567000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:00:00')),
(16, 11, NULL, 2, 50000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:00:00')),                                 -- Bánh flan (MỚI)
(17, NULL, 1, 2, 578000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 13:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 13:00:00')),                                 -- Combo 1 (MỚI)
(18, NULL, 2, 1, 159000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 4 DAY), ' 18:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 4 DAY), ' 18:00:00')),                                 -- Combo 2 (MỚI)
(19, NULL, 3, 1, 229000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 5 DAY), ' 19:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 5 DAY), ' 19:00:00')),                                 -- Combo 3 (MỚI)
(20, NULL, 4, 1, 219000.00, CONCAT(DATE_SUB(CURDATE(), INTERVAL 6 DAY), ' 12:00:00'),
 CONCAT(DATE_SUB(CURDATE(), INTERVAL 6 DAY), ' 12:00:00')),                                 -- Combo 4 (MỚI)

-- Tháng này (Orders 21-22)
(21, 6, NULL, 8, 2500000.00, CONCAT(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) + INTERVAL 1 DAY, ' 12:00:00'),
 CONCAT(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) + INTERVAL 1 DAY, ' 12:00:00')),
(22, 4, NULL, 15, 3200000.00, CONCAT(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) + INTERVAL 5 DAY, ' 18:00:00'),
 CONCAT(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) + INTERVAL 5 DAY, ' 18:00:00')),

-- Tháng trước (Orders 23-27)
(23, 3, NULL, 10, 1000000.00,
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 25 DAY), ' 12:00:00'),
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 25 DAY), ' 12:00:00')),
(24, 6, NULL, 4, 1200000.00,
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 15 DAY), ' 13:00:00'),
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 15 DAY), ' 13:00:00')),
(25, 8, NULL, 12, 1800000.00,
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 10 DAY), ' 18:00:00'),
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 10 DAY), ' 18:00:00')),
(26, 4, NULL, 15, 2200000.00,
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 5 DAY), ' 19:00:00'),
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 5 DAY), ' 19:00:00')),
(27, 3, NULL, 15, 1500000.00,
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 1 DAY), ' 20:00:00'),
 CONCAT(DATE_SUB(LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), INTERVAL 1 DAY), ' 20:00:00'));


INSERT INTO feedbacks (rating, comment, item_id, user_id, is_featured, status, created_at, updated_at)
VALUES 
    (5, 'Không gian nhà hàng thực sự sang trọng. Tối qua tôi đã có một bữa tối tuyệt vời cùng gia đình. Bò bít tết sốt tiêu đen rất mềm và thơm!', 4, 2, TRUE, 'APPROVED', DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
    (5, 'Lần đầu trải nghiệm tại CrownDine và tôi vô cùng ấn tượng. Phục vụ chu đáo, món Súp cua trứng bắc thảo rất đậm đà.', 1, 3, TRUE, 'APPROVED', DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
    (4, 'Món gà chiên mắm rất ngon, da giòn rụm. Tuy nhiên quán hơi đông vào giờ cao điểm, nên đặt bàn trước.', 3, 1, TRUE, 'APPROVED', DATE_SUB(NOW(), INTERVAL 1 WEEK), NOW()),
    (5, 'Hải sản ở đây cực kỳ tươi. Tôm hấp sả giữ được vị ngọt tự nhiên. Sẽ quay lại nhiều lần nữa!', 8, 2, TRUE, 'APPROVED', DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
    (5, 'Bánh flan caramel là món kết thúc bữa ăn hoàn hảo. Không quá ngọt, độ béo vừa phải. Tuyệt vời!', 11, 3, TRUE, 'APPROVED', DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),
    (4, 'Súp thanh đạm, rất vừa miệng.', 1, 1, FALSE, 'APPROVED', NOW(), NOW()),
    (5, 'Cá ngừ tươi, sốt salad rất đặc biệt.', 2, 2, FALSE, 'APPROVED', NOW(), NOW()),
    (4, 'Rau xanh giòn, cảm giác rất healthy.', 2, 3, FALSE, 'APPROVED', NOW(), NOW()),
    (5, 'Da heo giòn tan, thịt mềm mọng nước.', 5, 1, FALSE, 'APPROVED', NOW(), NOW()),
    (5, 'Món này ăn với cơm thì tuyệt vời.', 5, 2, FALSE, 'APPROVED', NOW(), NOW()),
    (4, 'Nước lẩu hơi cay nhưng rất ngon.', 6, 1, FALSE, 'APPROVED', NOW(), NOW()),
    (4, 'Rau muống xào tỏi thơm phức.', 7, 3, FALSE, 'APPROVED', NOW(), NOW()),
    (5, 'Đào miếng to, trà thơm và không quá ngọt.', 9, 1, FALSE, 'APPROVED', NOW(), NOW()),
    (4, 'Giải nhiệt rất tốt cho những ngày nóng.', 9, 2, FALSE, 'APPROVED', NOW(), NOW()),
    (5, 'Coca mát lạnh, phục vụ nhanh.', 10, 3, FALSE, 'APPROVED', NOW(), NOW());

INSERT INTO feedbacks (rating, comment, combo_id, user_id, is_featured, status, created_at, updated_at)
VALUES 
    (5, 'Combo rất hời cho 2 người ăn, đủ no và ngon.', 1, 2, FALSE, 'APPROVED', NOW(), NOW()),
    (4, 'Sự kết hợp hoàn hảo giữa gà và salad.', 2, 3, FALSE, 'APPROVED', NOW(), NOW()),
    (5, 'Bít tết chín vừa, súp cua khai vị rất hợp.', 3, 1, FALSE, 'APPROVED', NOW(), NOW()),
    (5, 'Hải sản tươi ngon, đúng chất healthy.', 4, 3, FALSE, 'APPROVED', NOW(), NOW()),
    (5, 'Combo tráng miệng rất chill cho buổi chiều.', 5, 2, FALSE, 'APPROVED', NOW(), NOW());

INSERT INTO favorites (user_id, item_id, combo_id, created_at, updated_at)
VALUES 
    (2, 4, NULL, NOW(), NOW()),
    (2, NULL, 1, NOW(), NOW()),
    (3, 1, NULL, NOW(), NOW());
