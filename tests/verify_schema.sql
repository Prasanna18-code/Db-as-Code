-- verify_schema.sql
-- Check if the expected tables exist in the public schema
DO $$ 
BEGIN
    -- Check for users table
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
        RAISE EXCEPTION 'Table "users" does not exist';
    END IF;

    -- Check for products table
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'products') THEN
        RAISE EXCEPTION 'Table "products" does not exist';
    END IF;

    -- Check for orders table
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'orders') THEN
        RAISE EXCEPTION 'Table "orders" does not exist';
    END IF;

    RAISE NOTICE 'All required tables (users, products, orders) are present.';
END $$;
