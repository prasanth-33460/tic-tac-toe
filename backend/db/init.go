package db

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
)

func InitializeDatabase(ctx context.Context, logger runtime.Logger, database *sql.DB, nk runtime.NakamaModule) error {
	logger.Info("Initializing custom database schema...")

	query := `
    CREATE TABLE IF NOT EXISTS player_status (
        user_id VARCHAR(255) PRIMARY KEY,
        is_banned BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS player_stats (
        user_id VARCHAR(255) PRIMARY KEY,
        total_wins INT DEFAULT 0,
        total_losses INT DEFAULT 0,
        total_draws INT DEFAULT 0,
        skill_rating INT DEFAULT 1000,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS match_history (
        match_id VARCHAR(255) PRIMARY KEY,
        winner_id VARCHAR(255),
        loser_id VARCHAR(255),
        mode VARCHAR(20),
        duration_seconds INT,
        completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS match_chat (
        id SERIAL PRIMARY KEY,
        user_id VARCHAR(255),
        username VARCHAR(255),
        message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    `

	_, err := database.ExecContext(ctx, query)
	if err != nil {
		logger.Error("Failed to initialize database: %v", err)
		return err
	}

	// Initialize leaderboards
	if err := EnsureLeaderboards(logger, nk); err != nil {
		logger.Error("Failed to initialize leaderboards: %v", err)
		return err
	}

	logger.Info("Database schema initialized successfully!")
	return nil
}

// EnsureLeaderboards creates the required leaderboards if they do not exist.
// This can be called during initialization or on-demand if a leaderboard is missing.
func EnsureLeaderboards(logger runtime.Logger, nk runtime.NakamaModule) error {
	logger.Info("Ensuring leaderboards exist...")

	ctx := context.Background()

	// Create global_wins leaderboard - authoritative so only server can write
	if err := nk.LeaderboardCreate(ctx, "global_wins", true, "desc", "incr", "", nil); err != nil {
		logger.Warn("Failed to create global_wins leaderboard (may already exist): %v", err)
	}

	// Create win_streaks leaderboard - authoritative so only server can write
	if err := nk.LeaderboardCreate(ctx, "win_streaks", true, "desc", "set", "", nil); err != nil {
		logger.Warn("Failed to create win_streaks leaderboard (may already exist): %v", err)
	}

	logger.Info("Leaderboards ensured successfully!")
	return nil
}
