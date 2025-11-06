package rpc

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/heroiclabs/nakama-common/runtime"
)

func RPCFindMatch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req MatchRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		logger.Error("Failed to unmarshal match request: %v", err)
		return "", fmt.Errorf("invalid request")
	}

	if req.SkillLevel < 0 || req.SkillLevel > 100 {
		return "", fmt.Errorf("skill level must be between 0-100")
	}

	if req.Mode == "" {
		req.Mode = "classic"
	}

	// FIXED: Only primitive, JSON-serializable types
	params := map[string]interface{}{
		"mode": req.Mode,
	}

	matchID, err := nk.MatchCreate(ctx, "tictactoe", params)
	if err != nil {
		logger.Error("Failed to create match: %v", err)
		return "", fmt.Errorf("match creation failed")
	}

	response := map[string]interface{}{
		"match_id": matchID,
		"mode":     req.Mode,
	}

	responseJSON, err := json.Marshal(response)
	if err != nil {
		logger.Error("Failed to marshal response: %v", err)
		return "", fmt.Errorf("internal error")
	}

	return string(responseJSON), nil
}

func RPCCreateQuickMatch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req MatchRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		req.Mode = "classic"
	}

	params := map[string]interface{}{
		"mode": req.Mode,
	}

	matchID, err := nk.MatchCreate(ctx, "tictactoe", params)
	if err != nil {
		logger.Error("Failed to create match: %v", err)
		return "", fmt.Errorf("match creation failed")
	}

	response := map[string]string{
		"match_id": matchID,
		"mode":     req.Mode,
	}

	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}

func MatchmakerMatched(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, entries []runtime.MatchmakerEntry) (string, error) {
	if len(entries) != 2 {
		logger.Error("Invalid number of players matched: %d", len(entries))
		return "", fmt.Errorf("invalid player count")
	}

	mode := "classic"
	if props := entries[0].GetProperties(); props != nil {
		if modeVal, ok := props["mode"]; ok {
			if modeStr, ok := modeVal.(string); ok {
				mode = modeStr
			}
		}
	}

	params := map[string]interface{}{
		"mode": mode,
	}

	matchID, err := nk.MatchCreate(ctx, "tictactoe", params)
	if err != nil {
		logger.Error("Failed to create match from matchmaker: %v", err)
		return "", err
	}

	logger.Info("Matchmaker created match %s with %d players", matchID, len(entries))
	return matchID, nil
}
