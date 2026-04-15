package rpc

import (
	"context"
	"database/sql"
	"encoding/json"

	"github.com/heroiclabs/nakama-common/runtime"
	dbpkg "github.com/prasanth-33460/tic-tac-toe/backend/db"
	"github.com/prasanth-33460/tic-tac-toe/backend/match"
)

// RPCGetLeaderboard returns the top-10 entries from both the global wins
// and win-streaks leaderboards.
func RPCGetLeaderboard(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	response := LeaderboardResponse{
		GlobalWins: []LeaderboardEntry{},
		WinStreaks: []LeaderboardEntry{},
	}

	if err := dbpkg.EnsureLeaderboards(logger, nk); err != nil {
		logger.Warn("Leaderboard ensure failed: %v", err)
	}

	serverCtx := context.Background()
	const limit = 10

	if records, _, _, _, err := nk.LeaderboardRecordsList(serverCtx, match.LeaderboardGlobalWins, nil, limit, "", 0); err != nil {
		logger.Error("Wins leaderboard fetch failed: %v", err)
	} else {
		for _, r := range records {
			response.GlobalWins = append(response.GlobalWins, LeaderboardEntry{
				UserID:   r.GetOwnerId(),
				Username: r.GetUsername().GetValue(),
				Score:    r.GetScore(),
				Rank:     r.GetRank(),
			})
		}
	}

	if records, _, _, _, err := nk.LeaderboardRecordsList(serverCtx, match.LeaderboardWinStreaks, nil, limit, "", 0); err != nil {
		logger.Error("Streaks leaderboard fetch failed: %v", err)
	} else {
		for _, r := range records {
			response.WinStreaks = append(response.WinStreaks, LeaderboardEntry{
				UserID:   r.GetOwnerId(),
				Username: r.GetUsername().GetValue(),
				Score:    r.GetScore(),
				Rank:     r.GetRank(),
			})
		}
	}

	b, _ := json.Marshal(response)
	return string(b), nil
}
