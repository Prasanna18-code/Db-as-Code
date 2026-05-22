-- Adds referential integrity constraints
ALTER TABLE orders
ADD CONSTRAINT fk_orders_users
FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;

ALTER TABLE orders
ADD CONSTRAINT fk_orders_products
FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE;
