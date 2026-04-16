-- 003: Completed match records
CREATE TABLE IF NOT EXISTS match_history (
    match_id         VARCHAR(255) PRIMARY KEY,
    winner_id        VARCHAR(255),
    loser_id         VARCHAR(255),
    mode             VARCHAR(20),
    duration_seconds INT,
    completed_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
