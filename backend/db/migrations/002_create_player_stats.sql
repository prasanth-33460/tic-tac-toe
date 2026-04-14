-- 002: Aggregated player statistics
CREATE TABLE IF NOT EXISTS player_stats (
    user_id      VARCHAR(255) PRIMARY KEY,
    total_wins   INT       DEFAULT 0,
    total_losses INT       DEFAULT 0,
    total_draws  INT       DEFAULT 0,
    skill_rating INT       DEFAULT 1000,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
