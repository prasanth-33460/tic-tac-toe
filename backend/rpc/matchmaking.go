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

	if payload != "" && payload != "{}" {
		if err := json.Unmarshal([]byte(payload), &req); err != nil {
			logger.Warn("Failed to unmarshal: %v", err)
			req.Mode = "classic"
		}
	} else {
		req.Mode = "classic"
	}

	if req.Mode == "" {
		req.Mode = "classic"
	}

	if req.SkillLevel < 0 || req.SkillLevel > 100 {
		req.SkillLevel = 50
	}

	logger.Info("🎯 Finding match with mode: %s, skill: %d", req.Mode, req.SkillLevel)

	params := map[string]interface{}{
		"mode": req.Mode,
	}

	matchID, err := nk.MatchCreate(ctx, "tictactoe", params)
	if err != nil {
		logger.Error("❌ Failed to create match: %v", err)
		return "", fmt.Errorf("match creation failed")
	}

	response := map[string]interface{}{
		"matchId": matchID,
		"mode":    req.Mode,
	}

	responseJSON, err := json.Marshal(response)
	if err != nil {
		logger.Error("Failed to marshal response: %v", err)
		return "", fmt.Errorf("internal error")
	}

	logger.Info("✅ Match found: %s", matchID)
	return string(responseJSON), nil
}

func RPCCreateQuickMatch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req MatchRequest

	if payload != "" && payload != "{}" {
		if err := json.Unmarshal([]byte(payload), &req); err != nil {
			logger.Warn("Failed to unmarshal: %v", err)
			req.Mode = "classic"
		}
	} else {
		req.Mode = "classic"
	}

	if req.Mode == "" {
		req.Mode = "classic"
	}

	logger.Info("🎯 Creating quick match with mode: %s", req.Mode)

	params := map[string]interface{}{
		"mode": req.Mode,
	}

	matchID, err := nk.MatchCreate(ctx, "tictactoe", params)
	if err != nil {
		logger.Error("❌ Failed to create match: %v", err)
		return "", fmt.Errorf("match creation failed")
	}

	// ✅ FIXED: Use map[string]interface{} not map[string]string
	response := map[string]interface{}{
		"matchId": matchID,
		"mode":    req.Mode,
	}

	responseJSON, err := json.Marshal(response)
	if err != nil {
		logger.Error("Failed to marshal response: %v", err)
		return "", fmt.Errorf("internal error")
	}

	logger.Info("✅ Match created successfully: %s", matchID)
	return string(responseJSON), nil
}

func MatchmakerMatched(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, entries []runtime.MatchmakerEntry) (string, error) {
	if len(entries) != 2 {
		logger.Error("❌ Invalid number of players matched: %d", len(entries))
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
