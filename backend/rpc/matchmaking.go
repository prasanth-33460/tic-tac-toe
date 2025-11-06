package rpc

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/heroiclabs/nakama-common/runtime"
)

// RPCFindMatch uses the matchmaker to pair players automatically
func RPCFindMatch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req MatchRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		logger.Error("Failed to unmarshal match request: %v", err)
		return "", fmt.Errorf("invalid request")
	}

	// Default to classic mode
	if req.Mode == "" {
		req.Mode = "classic"
	}

	// Set up match parameters with enhanced matching criteria
	params := map[string]interface{}{
		"mode":        req.Mode,
		"skillLevel":  req.SkillLevel,
		"preferences": req.Preferences,
		"metadata":    req.Metadata,
	}

	// Create match labels for sophisticated filtering
	labels := []string{
		fmt.Sprintf("+label.mode:%s", req.Mode),
		fmt.Sprintf("+label.skillRange:%d-%d",
			req.SkillLevel-req.RatingRange,
			req.SkillLevel+req.RatingRange),
	}

	// Add preference-based labels
	for key, value := range req.Preferences {
		labels = append(labels, fmt.Sprintf("+label.pref_%s:%s", key, value))
	}

	// Combine all labels
	label := strings.Join(labels, " ")

	// Try to find an existing match first
	limit := 1
	authoritative := true
	matches, err := nk.MatchList(ctx, limit, authoritative, label, nil, nil, "")
	if err != nil {
		logger.Error("Failed to list matches: %v", err)
		return "", fmt.Errorf("matchmaking failed")
	}

	var matchID string
	if len(matches) > 0 {
		// Join existing match
		matchID = matches[0].MatchId
	} else {
		// Create new match if no suitable match found
		matchID, err = nk.MatchCreate(ctx, "tictactoe", params)
		if err != nil {
			logger.Error("Failed to create match: %v", err)
			return "", fmt.Errorf("match creation failed")
		}
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

// RPCCreateQuickMatch creates an immediate match for testing/private games
func RPCCreateQuickMatch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req MatchRequest
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		req.Mode = "classic"
	}

	// Create match with specified mode
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

// MatchmakerMatched is called when the matchmaker finds suitable players
func MatchmakerMatched(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, entries []runtime.MatchmakerEntry) (string, error) {
	if len(entries) != 2 {
		logger.Error("Invalid number of players matched: %d", len(entries))
		return "", fmt.Errorf("invalid player count")
	}

	// Get the game mode from the first player's properties
	mode := "classic"
	if props := entries[0].GetProperties(); props != nil {
		if modeVal, ok := props["mode"]; ok {
			if modeStr, ok := modeVal.(string); ok {
				mode = modeStr
			}
		}
	}

	// Create new match for matched players
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
