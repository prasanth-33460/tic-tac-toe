-- 004: In-match chat messages
CREATE TABLE IF NOT EXISTS match_chat (
    id         SERIAL PRIMARY KEY,
    user_id    VARCHAR(255),
    username   VARCHAR(255),
    message    TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
