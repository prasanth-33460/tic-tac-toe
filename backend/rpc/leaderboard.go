package rpc

import (
	"context"
	"database/sql"
	"encoding/json"

	"github.com/heroiclabs/nakama-common/runtime"
	dbpkg "github.com/prasanth-33460/tic-tac-toe/backend/db"
)

func RPCGetLeaderboard(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	response := LeaderboardResponse{
		GlobalWins: []LeaderboardEntry{},
		WinStreaks: []LeaderboardEntry{},
	}

	// Ensure leaderboards exist before fetching (create on demand if missing)
	if err := dbpkg.EnsureLeaderboards(logger, nk); err != nil {
		logger.Warn("Failed to ensure leaderboards before fetch: %v", err)
	}

	serverCtx := context.Background()

	winsRecords, _, _, _, err := nk.LeaderboardRecordsList(serverCtx, "global_wins", nil, 10, "", 0)
	if err != nil {
		logger.Error("Failed to fetch wins leaderboard: %v", err)
	} else {
		logger.Info("Fetched %d wins leaderboard records", len(winsRecords))
		for _, record := range winsRecords {
			response.GlobalWins = append(response.GlobalWins, LeaderboardEntry{
				UserID:   record.GetOwnerId(),
				Username: record.GetUsername().GetValue(),
				Score:    record.GetScore(),
				Rank:     record.GetRank(),
			})
		}
	}

	streakRecords, _, _, _, err := nk.LeaderboardRecordsList(serverCtx, "win_streaks", nil, 10, "", 0)
	if err != nil {
		logger.Error("Failed to fetch streaks leaderboard: %v", err)
	} else {
		logger.Info("Fetched %d streak leaderboard records", len(streakRecords))
		for _, record := range streakRecords {
			response.WinStreaks = append(response.WinStreaks, LeaderboardEntry{
				UserID:   record.GetOwnerId(),
				Username: record.GetUsername().GetValue(),
				Score:    record.GetScore(),
				Rank:     record.GetRank(),
			})
		}
	}

	logger.Info("Returning leaderboard response with %d wins and %d streaks", len(response.GlobalWins), len(response.WinStreaks))
	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}
