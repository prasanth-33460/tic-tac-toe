package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
)

func Init(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {
	logger.Info("Initializing Tic-Tac-Toe server")

	if err := RegisterRoutes(ctx, logger, db, nk, initializer); err != nil {
		logger.Error("Failed to register routes: %v", err)
		return err
	}

	logger.Info("Tic-Tac-Toe server initialized successfully!")
	return nil
}
