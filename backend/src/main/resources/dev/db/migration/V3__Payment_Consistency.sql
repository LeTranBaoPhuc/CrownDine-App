-- Align the initial payment enums with the Java model and retain deposit snapshots.
ALTER TABLE payments
  MODIFY status ENUM('PENDING','SUCCESS','FAILED','CANCELLED','EXPIRED','PAID','REFUNDED'),
  MODIFY type ENUM('PAYMENT','REFUND','DEPOSIT','SETTLEMENT'),
  MODIFY target ENUM('BILL_SETTLEMENT','RESERVATION_DEPOSIT','RESERVATION','ORDER'),
  MODIFY source ENUM('CASHIER','CUSTOMER_ONLINE','STAFF_MOBILE','CLIENT_APP','POS_COUNTER'),
  ADD COLUMN table_deposit_amount DECIMAL(38,2) NULL,
  ADD COLUMN checkout_url VARCHAR(1000) NULL;
UPDATE payments SET status = 'SUCCESS' WHERE status = 'PAID';
UPDATE payments SET target = 'RESERVATION' WHERE target = 'RESERVATION_DEPOSIT';
UPDATE payments SET target = 'ORDER' WHERE target = 'BILL_SETTLEMENT';
UPDATE payments SET type = CASE WHEN target = 'RESERVATION' THEN 'DEPOSIT' ELSE 'SETTLEMENT' END WHERE type = 'PAYMENT';
UPDATE payments SET source = CASE WHEN source = 'CUSTOMER_ONLINE' THEN 'CLIENT_APP' ELSE 'POS_COUNTER' END
 WHERE source IN ('CASHIER','CUSTOMER_ONLINE','STAFF_MOBILE');
-- Do not guess the table/food split of historical deposits. Keep NULL and
-- require reconciliation before settling an active order backed by legacy data.
