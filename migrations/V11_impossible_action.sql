-- This first command is perfectly valid:
CREATE TABLE temporary_demo (id INT);

-- This second command will crash (because fake_table doesn't exist):
ALTER TABLE fake_table ADD COLUMN email TEXT;
