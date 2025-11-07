package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
	dbpkg "github.com/prasanth-33460/tic-tac-toe/backend/db"
)

func InitModule(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {
	if err := dbpkg.InitializeDatabase(ctx, logger, db, nk); err != nil {
		logger.Error("Database initialization failed: %v", err)
		return err
	}

	if err := RegisterRoutes(ctx, logger, db, nk, initializer); err != nil {
		logger.Error("Failed to register routes: %v", err)
		return err
	}

	logger.Info("Tic-Tac-Toe game server initialized successfully!")
	return nil
}
