package rpc

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/heroiclabs/nakama-common/runtime"
	dbpkg "github.com/prasanth-33460/tic-tac-toe/backend/db"
)

// RPCBanPlayer marks a player as banned so they cannot join matches.
func RPCBanPlayer(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req BanRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		return "", fmt.Errorf("invalid request")
	}
	if req.TargetUserID == "" {
		return "", fmt.Errorf("target_user_id required")
	}

	repo := dbpkg.NewRepository(db)
	if err := repo.BanPlayer(ctx, req.TargetUserID); err != nil {
		logger.Error("Ban failed for %s: %v", req.TargetUserID, err)
		return "", fmt.Errorf("ban failed")
	}

	logger.Info("Player %s banned — reason: %s", req.TargetUserID, req.Reason)

	resp, _ := json.Marshal(BanResponse{
		Success: true,
		Message: fmt.Sprintf("Player %s has been banned", req.TargetUserID),
	})
	return string(resp), nil
}

// RPCUnbanPlayer lifts a ban on a player.
func RPCUnbanPlayer(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req BanRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		return "", fmt.Errorf("invalid request")
	}
	if req.TargetUserID == "" {
		return "", fmt.Errorf("target_user_id required")
	}

	repo := dbpkg.NewRepository(db)
	if err := repo.UnbanPlayer(ctx, req.TargetUserID); err != nil {
		logger.Error("Unban failed for %s: %v", req.TargetUserID, err)
		return "", fmt.Errorf("unban failed")
	}

	resp, _ := json.Marshal(BanResponse{
		Success: true,
		Message: fmt.Sprintf("Player %s has been unbanned", req.TargetUserID),
	})
	return string(resp), nil
}
