package rpc

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/heroiclabs/nakama-common/runtime"
)

func RPCBanPlayer(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req BanRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		logger.Error("Failed to unmarshal ban request: %v", err)
		return "", fmt.Errorf("invalid request")
	}

	if req.TargetUserID == "" {
		return "", fmt.Errorf("target_user_id required")
	}

	query := `
    INSERT INTO player_status (user_id, is_banned)
    VALUES ($1, true)
    ON CONFLICT (user_id) DO UPDATE SET is_banned = true
    `

	_, err := db.ExecContext(ctx, query, req.TargetUserID)
	if err != nil {
		logger.Error("Failed to ban player: %v", err)
		return "", fmt.Errorf("ban failed")
	}

	logger.Info("Player %s banned. Reason: %s", req.TargetUserID, req.Reason)

	response := BanResponse{
		Success: true,
		Message: fmt.Sprintf("Player %s has been banned", req.TargetUserID),
	}

	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}

func RPCUnbanPlayer(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req BanRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		return "", fmt.Errorf("invalid request")
	}

	query := `UPDATE player_status SET is_banned = false WHERE user_id = $1`
	_, err := db.ExecContext(ctx, query, req.TargetUserID)
	if err != nil {
		logger.Error("Failed to unban player: %v", err)
		return "", fmt.Errorf("unban failed")
	}

	response := BanResponse{
		Success: true,
		Message: fmt.Sprintf("Player %s has been unbanned", req.TargetUserID),
	}

	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}
