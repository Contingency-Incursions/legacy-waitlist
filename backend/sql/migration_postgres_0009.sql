-- Add columns to fleet table
ALTER TABLE fleet ADD COLUMN boss_system_id BIGINT;
ALTER TABLE fleet ADD COLUMN max_size BIGINT NOT NULL;
ALTER TABLE fleet ADD COLUMN visible BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE fleet ADD COLUMN error_count BIGINT NOT NULL DEFAULT 0;
ALTER TABLE fleet DROP COLUMN is_updating;

-- Modify column data type in fleet_activity
ALTER TABLE fleet_activity ALTER COLUMN is_boss SET DATA TYPE BOOLEAN;

-- Remove foreign key constraint and columns from waitlist_entry table
ALTER TABLE waitlist_entry DROP CONSTRAINT IF EXISTS waitlist_entry_ibfk_1;
ALTER TABLE waitlist_entry DROP COLUMN waitlist_id;

-- Drop the waitlist table
DROP TABLE IF EXISTS waitlist;

-- Drop the check constraint, change column name, and add new check constraint for waitlist_entry_fit table
ALTER TABLE waitlist_entry_fit DROP CONSTRAINT IF EXISTS waitlist_entry_fit_chk_1;
ALTER TABLE waitlist_entry_fit RENAME COLUMN approved TO state;
ALTER TABLE waitlist_entry_fit ADD CONSTRAINT fit_state CHECK (state IN ('pending', 'approved', 'rejected'));
