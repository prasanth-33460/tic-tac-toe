package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/prasanth-33460/tic-tac-toe/backend/match"
	"github.com/prasanth-33460/tic-tac-toe/backend/rpc"
)

// RegisterRoutes wires up the match handler and all RPC endpoints.
func RegisterRoutes(_ context.Context, _ runtime.Logger, _ *sql.DB, _ runtime.NakamaModule, init runtime.Initializer) error {
	if err := registerMatchHandler(init); err != nil {
		return err
	}
	return registerRPCEndpoints(init)
}

func registerMatchHandler(init runtime.Initializer) error {
	return init.RegisterMatch("tictactoe", func(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule) (runtime.Match, error) {
		return &match.Match{}, nil
	})
}

func registerRPCEndpoints(init runtime.Initializer) error {
	endpoints := map[string]func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, string) (string, error){
		"find_match":        rpc.RPCFindMatch,
		"create_quick_match": rpc.RPCCreateQuickMatch,
		"get_match_by_code": rpc.RPCGetMatchIdByCode,
		"get_match_info":    rpc.RPCGetMatchInfo,
		"get_leaderboard":   rpc.RPCGetLeaderboard,
		"request_rematch":   rpc.RPCRequestRematch,
		"ban_player":        rpc.RPCBanPlayer,
		"unban_player":      rpc.RPCUnbanPlayer,
	}

	for id, fn := range endpoints {
		if err := init.RegisterRpc(id, fn); err != nil {
			return err
		}
	}
	return nil
}
