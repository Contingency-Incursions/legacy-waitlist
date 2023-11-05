-- Character & Auth related tables
CREATE TABLE alliance (
  id BIGINT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE corporation (
  id BIGINT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  alliance_id BIGINT,
  updated_at BIGINT NOT NULL,
  CONSTRAINT alliance_id FOREIGN KEY (alliance_id) REFERENCES alliance (id)
);

CREATE TABLE character (
  id BIGINT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  corporation_id BIGINT,
  last_seen BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW())),
  CONSTRAINT character_corporation FOREIGN KEY (corporation_id) REFERENCES corporation (id)
);

CREATE TABLE access_token (
  character_id BIGINT NOT NULL,
  access_token VARCHAR(2048) NOT NULL,
  expires BIGINT NOT NULL,
  scopes VARCHAR(1024) NOT NULL,
  PRIMARY KEY (character_id),
  CONSTRAINT access_token_character_id FOREIGN KEY (character_id) REFERENCES character (id)
);

CREATE TABLE refresh_token (
  character_id BIGINT NOT NULL,
  refresh_token VARCHAR(255) NOT NULL,
  scopes VARCHAR(1024) NOT NULL,
  PRIMARY KEY (character_id),
  CONSTRAINT refresh_token_character_id FOREIGN KEY (character_id) REFERENCES character (id)
);

CREATE TABLE admin (
  character_id BIGINT PRIMARY KEY NOT NULL,
  role VARCHAR(64) NOT NULL,
  granted_at BIGINT NOT NULL,
  granted_by_id BIGINT NOT NULL,
  CONSTRAINT character_role FOREIGN KEY (character_id) REFERENCES character (id),
  CONSTRAINT admin_character FOREIGN KEY (granted_by_id) REFERENCES character (id)
);

INSERT INTO admin values (666532715, "Leadership", 666532715, 666532715);

CREATE TABLE alt_character (
  account_id BIGINT NOT NULL,
  alt_id BIGINT NOT NULL,
  PRIMARY KEY (account_id, alt_id),
  CONSTRAINT alt_character_account_id FOREIGN KEY (account_id) REFERENCES character (id),
  CONSTRAINT alt_character_alt_id FOREIGN KEY (alt_id) REFERENCES character (id)
);

-- Feature tables
CREATE TABLE announcement (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  message VARCHAR(512) NOT NULL,
  is_alert BOOLEAN NOT NULL DEFAULT FALSE,
  pages TEXT,
  created_by_id BIGINT NOT NULL,
  created_at BIGINT NOT NULL,
  revoked_by_id BIGINT,
  revoked_at BIGINT,
  CONSTRAINT announcement_by FOREIGN KEY (created_by_id) REFERENCES character (id),
  CONSTRAINT announcement_revoked_by FOREIGN KEY (revoked_by_id) REFERENCES character (id)
);

CREATE TABLE ban (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  entity_id BIGINT NOT NULL,
  entity_name VARCHAR(64),
  entity_type VARCHAR(16) NOT NULL CHECK (entity_type IN ('Account', 'Character', 'Corporation', 'Alliance')),
  issued_at BIGINT NOT NULL,
  issued_by BIGINT NOT NULL,
  public_reason VARCHAR(512),
  reason VARCHAR(512) NOT NULL,
  revoked_at BIGINT,
  revoked_by BIGINT,
  CONSTRAINT issued_by FOREIGN KEY (issued_by) REFERENCES character (id),
  CONSTRAINT revoked_by FOREIGN KEY (revoked_by) REFERENCES character (id)
);

CREATE TABLE badge (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name VARCHAR(64) NOT NULL UNIQUE,
  exclude_badge_id BIGINT,
  CONSTRAINT exclude_badge FOREIGN KEY (exclude_badge_id) REFERENCES badge (id) ON DELETE SET NULL
);

CREATE TABLE badge_assignment (
  characterId BIGINT NOT NULL,
  badgeId BIGINT NOT NULL,
  grantedById BIGINT,
  grantedAt BIGINT NOT NULL,
  CONSTRAINT badge_assignment_characterId FOREIGN KEY (characterId) REFERENCES character (id),
  CONSTRAINT badge_assignment_badgeId FOREIGN KEY (badgeId) REFERENCES badge (id) ON DELETE CASCADE,
  CONSTRAINT badge_assignment_grantedById FOREIGN KEY (grantedById) REFERENCES character (id)
);

-- Seed the database with some starting badges
INSERT INTO badge (name) VALUES ('BASTION'), ('LOGI'), ('RETIRED-LOGI'), ('WEB');

-- A pilot cannot have Logi and RETIRED-LOGI at once, update our seed
UPDATE badge SET exclude_badge_id = (SELECT id FROM badge WHERE name = 'RETIRED-LOGI') WHERE name = 'LOGI';
UPDATE badge SET exclude_badge_id = (SELECT id FROM badge WHERE name = 'LOGI') WHERE name = 'RETIRED-LOGI';

CREATE TABLE fitting (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  dna VARCHAR(1024) NOT NULL,
  hull INT NOT NULL,
  UNIQUE (dna)
);

CREATE TABLE implant_set (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  implants VARCHAR(255) NOT NULL,
  UNIQUE (implants)
);

CREATE TABLE fit_history (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  character_id BIGINT NOT NULL,
  fit_id BIGINT NOT NULL,
  implant_set_id BIGINT NOT NULL,
  logged_at BIGINT NOT NULL,
  CONSTRAINT fit_history_character_id FOREIGN KEY (character_id) REFERENCES character (id),
  CONSTRAINT fit_history_fit_id FOREIGN KEY (fit_id) REFERENCES fitting (id),
  CONSTRAINT fit_history_implant_set_id FOREIGN KEY (implant_set_id) REFERENCES implant_set (id)
);

CREATE TABLE fleet_activity (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  character_id BIGINT NOT NULL,
  fleet_id BIGINT NOT NULL,
  first_seen BIGINT NOT NULL,
  last_seen BIGINT NOT NULL,
  hull INT NOT NULL,
  has_left BOOLEAN NOT NULL,
  is_boss BOOLEAN NOT NULL,
  CONSTRAINT fleet_activity_character_id FOREIGN KEY (character_id) REFERENCES character (id)
);

CREATE TABLE skill_current (
  character_id BIGINT NOT NULL,
  skill_id INT NOT NULL,
  level SMALLINT NOT NULL,
  PRIMARY KEY (character_id, skill_id),
  CONSTRAINT skill_current_character_id FOREIGN KEY (character_id) REFERENCES character (id)
);

CREATE TABLE skill_history (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  character_id BIGINT NOT NULL,
  skill_id INT NOT NULL,
  old_level SMALLINT NOT NULL,
  new_level SMALLINT NOT NULL,
  logged_at BIGINT NOT NULL,
  CONSTRAINT skill_history_character_id FOREIGN KEY (character_id) REFERENCES character (id)
);

CREATE TABLE character_note (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  character_id BIGINT NOT NULL,
  author_id BIGINT NOT NULL,
  note TEXT NOT NULL,
  logged_at BIGINT NOT NULL,
  CONSTRAINT character_note_character_id FOREIGN KEY (character_id) REFERENCES character (id),
  CONSTRAINT character_note_author_id FOREIGN KEY (author_id) REFERENCES character (id)
);

-- Temporary things

CREATE TABLE fleet (
  id BIGINT NOT NULL PRIMARY KEY,
  boss_id BIGINT NOT NULL,
  boss_system_id BIGINT,
  max_size BIGINT NOT NULL,
  visible BOOLEAN NOT NULL DEFAULT FALSE,
  error_count BIGINT NOT NULL DEFAULT 0,
  CONSTRAINT fleet_boss_id FOREIGN KEY (boss_id) REFERENCES character (id)
);

CREATE TABLE fleet_squad (
  fleet_id BIGINT NOT NULL,
  category VARCHAR(10) NOT NULL,
  wing_id BIGINT NOT NULL,
  squad_id BIGINT NOT NULL,
  PRIMARY KEY (fleet_id, category),
  CONSTRAINT fleet_squad_fleet_id FOREIGN KEY (fleet_id) REFERENCES fleet (id)
);

CREATE TABLE waitlist_entry (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  account_id BIGINT NOT NULL,
  joined_at BIGINT NOT NULL,
  UNIQUE (waitlist_id, account_id),
  CONSTRAINT waitlist_entry_account_id FOREIGN KEY (account_id) REFERENCES character (id)
);

CREATE TABLE waitlist_entry_fit (
  id BIGINT NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  character_id BIGINT NOT NULL,
  entry_id BIGINT NOT NULL,
  fit_id BIGINT NOT NULL,
  implant_set_id BIGINT NOT NULL,
  state VARCHAR(10) NOT NULL DEFAULT 'pending',
  tags VARCHAR(255) NOT NULL,
  category VARCHAR(10) NOT NULL,
  fit_analysis TEXT,
  review_comment TEXT,
  cached_time_in_fleet BIGINT NOT NULL,
  is_alt BOOLEAN NOT NULL,
  CONSTRAINT waitlist_entry_fit_character_id FOREIGN KEY (character_id) REFERENCES character (id),
  CONSTRAINT waitlist_entry_fit_entry_id FOREIGN KEY (entry_id) REFERENCES waitlist_entry (id),
  CONSTRAINT waitlist_entry_fit_fit_id FOREIGN KEY (fit_id) REFERENCES fitting (id),
  CONSTRAINT waitlist_entry_fit_implant_set_id FOREIGN KEY (implant_set_id) REFERENCES implant_set (id),
  CONSTRAINT fit_state CHECK (state IN ('pending', 'approved', 'rejected'))
);

CREATE TABLE wiki_user (
  character_id BIGINT PRIMARY KEY NOT NULL,
  "user" VARCHAR(255) NOT NULL UNIQUE,
  hash VARCHAR(60) NOT NULL,
  mail VARCHAR(255) NOT NULL UNIQUE,
  CONSTRAINT wiki_character FOREIGN KEY (character_id) REFERENCES character (id)
);

CREATE TABLE role_mapping (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  waitlist_role VARCHAR(64) NOT NULL,
  dokuwiki_role VARCHAR(64) NOT NULL,
  UNIQUE (waitlist_role)
);

CREATE VIEW dokuwiki_user AS
SELECT
    w.user AS "user",
    c.name AS "name",
    w.hash AS "hash",
    w.mail AS "mail"
FROM wiki_user AS w
JOIN character AS c ON
     c.id = w.character_id;

CREATE VIEW dokuwiki_groups AS
SELECT
    u.user as "user",
    COALESCE(m.dokuwiki_role, LOWER(a.role)) AS "group"
FROM wiki_user as u
JOIN admin AS a USING (character_id)
LEFT JOIN role_mapping AS m ON
    m.waitlist_role = a.role;
