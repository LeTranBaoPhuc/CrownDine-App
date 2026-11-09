-- Allow guest users to chat without an account
ALTER TABLE `chat_conversations` MODIFY COLUMN `user_id` BIGINT NULL;
