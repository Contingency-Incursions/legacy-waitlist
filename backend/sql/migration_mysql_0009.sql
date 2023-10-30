ALTER TABLE fleet ADD COLUMN boss_system_id BIGINT;
ALTER TABLE fleet ADD COLUMN max_size BIGINT NOT NULL;
ALTER TABLE fleet ADD COLUMN visible BOOL NOT NULL DEFAULT FALSE;
ALTER TABLE fleet ADD COLUMN error_count BIGINT NOT NULL DEFAULT(0);
ALTER TABLE fleet DROP COLUMN is_updating;

ALTER TABLE fleet_activity ALTER COLUMN is_boss SET DATA TYPE BOOLEAN;

-- Remove foreign key constraint in waitlist_entry table
ALTER TABLE waitlist_entry DROP CONSTRAINT IF EXISTS waitlist_entry_ibfk_1;
ALTER TABLE waitlist_entry DROP COLUMN waitlist_id;
DROP TABLE waitlist;

ALTER TABLE waitlist_entry_fit DROP CONSTRAINT waitlist_entry_fit_chk_1;
ALTER TABLE waitlist_entry_fit CHANGE COLUMN approved state VARCHAR(10) NOT NULL DEFAULT 'pending';
ALTER TABLE waitlist_entry_fit ADD CONSTRAINT fit_state CHECK (state in ('pending', 'approved', 'rejected'));

