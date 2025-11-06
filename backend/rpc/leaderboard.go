package rpc

import (
	"context"
	"database/sql"
	"encoding/json"

	"github.com/heroiclabs/nakama-common/runtime"
)

func RPCGetLeaderboard(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	response := LeaderboardResponse{
		GlobalWins: []LeaderboardEntry{},
		WinStreaks: []LeaderboardEntry{},
	}

	winsRecords, _, _, _, err := nk.LeaderboardRecordsList(ctx, "global_wins", nil, 10, "", 0)
	if err != nil {
		logger.Error("Failed to fetch wins leaderboard: %v", err)
	} else {
		for _, record := range winsRecords {
			response.GlobalWins = append(response.GlobalWins, LeaderboardEntry{
				UserID:   record.GetOwnerId(),
				Username: record.GetUsername().GetValue(),
				Score:    record.GetScore(),
				Rank:     record.GetRank(),
			})
		}
	}

	streakRecords, _, _, _, err := nk.LeaderboardRecordsList(ctx, "win_streaks", nil, 10, "", 0)
	if err != nil {
		logger.Error("Failed to fetch streaks leaderboard: %v", err)
	} else {
		for _, record := range streakRecords {
			response.WinStreaks = append(response.WinStreaks, LeaderboardEntry{
				UserID:   record.GetOwnerId(),
				Username: record.GetUsername().GetValue(),
				Score:    record.GetScore(),
				Rank:     record.GetRank(),
			})
		}
	}

	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}
