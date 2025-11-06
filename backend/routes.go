package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/prasanth-33460/tic-tac-toe/backend/match"
	"github.com/prasanth-33460/tic-tac-toe/backend/rpc"
)

// RegisterRoutes registers all RPC endpoints and match handlers
func RegisterRoutes(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {
	// Register match handler
	if err := registerMatchHandler(initializer); err != nil {
		return err
	}

	// Register RPC endpoints
	if err := registerRPCEndpoints(initializer); err != nil {
		return err
	}

	return nil
}

func registerMatchHandler(initializer runtime.Initializer) error {
	return initializer.RegisterMatch("tictactoe", func(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule) (runtime.Match, error) {
		return &match.Match{}, nil
	})
}

func registerRPCEndpoints(initializer runtime.Initializer) error {
	// Matchmaking endpoints
	if err := initializer.RegisterRpc("find_match", rpc.RPCFindMatch); err != nil {
		return err
	}
	if err := initializer.RegisterRpc("create_quick_match", rpc.RPCCreateQuickMatch); err != nil {
		return err
	}

	// Leaderboard endpoints
	if err := initializer.RegisterRpc("get_leaderboard", rpc.RPCGetLeaderboard); err != nil {
		return err
	}

	return nil
}
