-- Rolls back V8 using a new forward migration (correct Flyway pattern)
ALTER TABLE users DROP COLUMN IF EXISTS temp_data;