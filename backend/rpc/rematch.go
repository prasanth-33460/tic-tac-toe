package rpc

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/heroiclabs/nakama-common/runtime"
)

// RPCRequestRematch sends a rematch signal to the match handler, which
// resets the board and starts a new round with the same players.
func RPCRequestRematch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userID, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok || userID == "" {
		return "", fmt.Errorf("authentication required")
	}

	var req RematchRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		return "", fmt.Errorf("invalid request")
	}

	if req.MatchID == "" {
		return "", fmt.Errorf("match_id required")
	}

	signalData, err := json.Marshal(map[string]string{
		"type":   "rematch_request",
		"userId": userID,
	})
	if err != nil {
		return "", fmt.Errorf("internal error")
	}

	result, err := nk.MatchSignal(ctx, req.MatchID, string(signalData))
	if err != nil {
		logger.Error("Rematch signal failed for match %s: %v", req.MatchID, err)
		return "", fmt.Errorf("rematch failed")
	}

	success := result == "rematch_accepted"
	resp, _ := json.Marshal(RematchResponse{
		Success: success,
		Message: result,
	})
	return string(resp), nil
}
