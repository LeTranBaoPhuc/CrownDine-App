-- =========================================================================
-- V2__Create_Shifts_Work_Schedules_Attendances.sql
-- Module: Staff Work Schedule & Attendance System
-- =========================================================================

-- 1. Shifts Table
CREATE TABLE IF NOT EXISTS `shifts` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_by` VARCHAR(255) DEFAULT NULL,
    `updated_by` VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Work Schedules Table
CREATE TABLE IF NOT EXISTS `work_schedules` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `staff_id` BIGINT NOT NULL,
    `shift_id` BIGINT NOT NULL,
    `work_date` DATE NOT NULL,
    `end_date` DATE DEFAULT NULL,
    `is_repeated` BIT(1) DEFAULT b'0',
    `repeat_group_id` VARCHAR(255) DEFAULT NULL,
    `days_of_week` VARCHAR(255) DEFAULT NULL,
    `status` VARCHAR(20) DEFAULT 'APPROVED',
    `note` VARCHAR(200) DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_by` VARCHAR(255) DEFAULT NULL,
    `updated_by` VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_work_schedules_staff_id` (`staff_id`),
    KEY `idx_work_schedules_shift_id` (`shift_id`),
    KEY `idx_work_schedules_work_date` (`work_date`),
    CONSTRAINT `fk_work_schedules_staff_id_users` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_work_schedules_shift_id_shifts` FOREIGN KEY (`shift_id`) REFERENCES `shifts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Attendances Table
CREATE TABLE IF NOT EXISTS `attendances` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `work_schedule_id` BIGINT DEFAULT NULL,
    `check_in_at` DATETIME DEFAULT NULL,
    `check_out_at` DATETIME DEFAULT NULL,
    `status` VARCHAR(50) DEFAULT 'NOT_PUNCHED',
    `attendance_type` VARCHAR(50) DEFAULT 'WORKING',
    `note` VARCHAR(500) DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_by` VARCHAR(255) DEFAULT NULL,
    `updated_by` VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_attendances_user_id` (`user_id`),
    KEY `idx_attendances_work_schedule_id` (`work_schedule_id`),
    CONSTRAINT `fk_attendances_user_id_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_attendances_work_schedule_id_work_schedules` FOREIGN KEY (`work_schedule_id`) REFERENCES `work_schedules` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Initial Shift Seed Data
INSERT INTO `shifts` (`id`, `name`, `start_time`, `end_time`, `created_at`, `updated_at`) VALUES
(1, 'Ca sáng', '06:00:00', '14:00:00', NOW(), NOW()),
(2, 'Ca chiều', '14:00:00', '22:00:00', NOW(), NOW()),
(3, 'Ca tối', '18:00:00', '23:30:00', NOW(), NOW()),
(4, 'Ca gãy', '10:00:00', '14:00:00', NOW(), NOW()),
(5, 'Ca full-time', '08:00:00', '17:00:00', NOW(), NOW())
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

