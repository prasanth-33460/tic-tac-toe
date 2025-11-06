package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/prasanth-33460/tic-tac-toe/backend/match"
)

func Init(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {
	logger.Info("Initializing Tic-Tac-Toe match handler")

	if err := initializer.RegisterMatch("tic-tac-toe", func(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule) (runtime.Match, error) {
		return &match.Match{}, nil
	}); err != nil {
		logger.Error("Failed to register match: %v", err)
		return err
	}

	logger.Info("Tic-Tac-Toe match handler registered successfully!")
	return nil
}
