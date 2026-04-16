-- 001: Player status table (bans, account flags)
CREATE TABLE IF NOT EXISTS player_status (
    user_id    VARCHAR(255) PRIMARY KEY,
    is_banned  BOOLEAN   DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
