package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"
)

// Repository handles all direct database operations. SQL lives here,
// not in the service or RPC layers.
type Repository struct {
	db *sql.DB
}

// NewRepository creates a new database repository.
func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// Player status (bans)

// IsPlayerBanned returns true if the player is currently banned.
func (r *Repository) IsPlayerBanned(ctx context.Context, userID string) (bool, error) {
	var banned bool
	err := r.db.QueryRowContext(ctx,
		`SELECT is_banned FROM player_status WHERE user_id = $1`,
		userID,
	).Scan(&banned)

	if err == sql.ErrNoRows {
		return false, nil
	}
	return banned, err
}

// BanPlayer sets the ban flag for a player (upsert).
func (r *Repository) BanPlayer(ctx context.Context, userID string) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO player_status (user_id, is_banned)
		 VALUES ($1, true)
		 ON CONFLICT (user_id) DO UPDATE SET is_banned = true`,
		userID,
	)
	return err
}

// UnbanPlayer clears the ban flag for a player.
func (r *Repository) UnbanPlayer(ctx context.Context, userID string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE player_status SET is_banned = false WHERE user_id = $1`,
		userID,
	)
	return err
}

// Match history

// RecordMatchResult persists the outcome of a completed match.
func (r *Repository) RecordMatchResult(ctx context.Context, matchID, winnerID string, loserID *string, mode string, startTime int64) error {
	duration := max(int(time.Now().Unix()-startTime), 0)

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO match_history (match_id, winner_id, loser_id, mode, duration_seconds)
		 VALUES ($1, $2, $3, $4, $5)
		 ON CONFLICT (match_id) DO NOTHING`,
		matchID, winnerID, loserID, mode, duration,
	)
	return err
}

// Chat

// InsertChatMessage stores a chat message.
func (r *Repository) InsertChatMessage(ctx context.Context, userID, username, message string) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO match_chat (user_id, username, message, created_at)
		 VALUES ($1, $2, $3, NOW())`,
		userID, username, message,
	)
	return err
}

// Helpers

// GenerateFallbackMatchID builds a match ID when the real one is unavailable.
func GenerateFallbackMatchID(winnerID string) string {
	return fmt.Sprintf("%s_%d", winnerID, time.Now().UnixMilli())
}
