package db

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"sort"

	"github.com/heroiclabs/nakama-common/runtime"
)

//go:embed migrations/*.sql
var migrationFS embed.FS

// InitializeDatabase runs all SQL migration files in order and creates therequired Nakama leaderboards.
func InitializeDatabase(ctx context.Context, logger runtime.Logger, database *sql.DB, nk runtime.NakamaModule) error {
	logger.Info("Running database migrations...")

	if err := runMigrations(ctx, logger, database); err != nil {
		return fmt.Errorf("migrations failed: %w", err)
	}

	if err := EnsureLeaderboards(logger, nk); err != nil {
		return fmt.Errorf("leaderboard setup failed: %w", err)
	}

	logger.Info("Database initialization complete")
	return nil
}

// runMigrations reads every .sql file under db/migrations/ (sorted by name)
// and executes them sequentially. Each file uses IF NOT EXISTS so they are
// safe to re-run.
func runMigrations(ctx context.Context, logger runtime.Logger, db *sql.DB) error {
	entries, err := migrationFS.ReadDir("migrations")
	if err != nil {
		return fmt.Errorf("reading migrations dir: %w", err)
	}

	// Sort by filename to guarantee execution order.
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].Name() < entries[j].Name()
	})

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		path := "migrations/" + entry.Name()
		content, err := migrationFS.ReadFile(path)
		if err != nil {
			return fmt.Errorf("reading %s: %w", path, err)
		}

		logger.Info("Applying migration: %s", entry.Name())
		if _, err := db.ExecContext(ctx, string(content)); err != nil {
			return fmt.Errorf("executing %s: %w", entry.Name(), err)
		}
	}

	return nil
}

// EnsureLeaderboards creates the required leaderboards if they do not exist.
// Safe to call multiple times — Nakama ignores duplicate creates.
func EnsureLeaderboards(logger runtime.Logger, nk runtime.NakamaModule) error {
	ctx := context.Background()

	if err := nk.LeaderboardCreate(ctx, "global_wins", true, "desc", "incr", "", nil); err != nil {
		logger.Warn("global_wins leaderboard create (may already exist): %v", err)
	}

	if err := nk.LeaderboardCreate(ctx, "win_streaks", true, "desc", "set", "", nil); err != nil {
		logger.Warn("win_streaks leaderboard create (may already exist): %v", err)
	}

	logger.Info("Leaderboards ready")
	return nil
}
