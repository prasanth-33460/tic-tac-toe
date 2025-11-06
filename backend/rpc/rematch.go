package rpc

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/heroiclabs/nakama-common/runtime"
)

func RPCRequestRematch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req RematchRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		logger.Error("Failed to unmarshal rematch request: %v", err)
		return "", fmt.Errorf("invalid request")
	}

	if req.MatchID == "" {
		return "", fmt.Errorf("match_id required")
	}

	response := RematchResponse{
		Success: true,
		Message: "Rematch request sent to opponent",
	}

	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}
