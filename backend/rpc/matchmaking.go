package rpc

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"math/rand"

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

	// Create a new match directly instead of using matchmaker
	params := map[string]interface{}{
		"mode": req.Mode,
	}

	matchID, err := nk.MatchCreate(ctx, "tictactoe", params)
	if err != nil {
		logger.Error("❌ Failed to create match: %v", err)
		return "", fmt.Errorf("match creation failed")
	}

	// Fix: Strip trailing dot if present (Nakama single node issue)
	if len(matchID) > 0 && matchID[len(matchID)-1] == '.' {
		matchID = matchID[:len(matchID)-1]
	}

	shortCode := generateShortCode(nk, ctx, logger)
	if shortCode == "" {
		return "", fmt.Errorf("failed to generate short code")
	}

	// store short code with match ID as JSON value
	matchData := map[string]string{"matchId": matchID}
	matchDataJSON, _ := json.Marshal(matchData)

	_, err = nk.StorageWrite(ctx, []*runtime.StorageWrite{{
		Collection:      "match_codes",
		Key:             shortCode,
		Value:           string(matchDataJSON),
		PermissionRead:  2, // public read
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.Error("Failed to store short code: %v", err)
		return "", fmt.Errorf("storage error")
	}

	response := map[string]interface{}{
		"matchId":   matchID,
		"shortCode": shortCode,
		"mode":      req.Mode,
	}

	responseJSON, err := json.Marshal(response)
	if err != nil {
		logger.Error("Failed to marshal response: %v", err)
		return "", fmt.Errorf("internal error")
	}

	logger.Info("✅ Match created successfully: %s", matchID)
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

	// Fix: Strip trailing dot if present (Nakama single node issue)
	if len(matchID) > 0 && matchID[len(matchID)-1] == '.' {
		matchID = matchID[:len(matchID)-1]
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
	logger.Info("Matchmaker matched %d players", len(entries))

	mode := "classic"
	if len(entries) > 0 {
		if m, ok := entries[0].GetProperties()["mode"].(string); ok {
			mode = m
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

	// Fix: Strip trailing dot if present (Nakama single node issue)
	if len(matchID) > 0 && matchID[len(matchID)-1] == '.' {
		matchID = matchID[:len(matchID)-1]
	}

	logger.Info("Matchmaker created match %s with %d players", matchID, len(entries))
	return matchID, nil
}

func generateShortCode(nk runtime.NakamaModule, ctx context.Context, logger runtime.Logger) string {
	for i := 0; i < 10; i++ {
		code := fmt.Sprintf("%06d", rand.Intn(1000000))
		// check if exists
		objects, err := nk.StorageRead(ctx, []*runtime.StorageRead{{
			Collection: "match_codes",
			Key:        code,
		}})
		if err != nil || len(objects) == 0 {
			return code
		}
	}
	logger.Error("Failed to generate unique short code")
	return ""
}

func RPCGetMatchIdByCode(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req struct {
		Code string `json:"code"`
	}
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		return "", fmt.Errorf("invalid payload")
	}

	objects, err := nk.StorageRead(ctx, []*runtime.StorageRead{{
		Collection: "match_codes",
		Key:        req.Code,
	}})
	if err != nil || len(objects) == 0 {
		logger.Warn("Code not found: %s", req.Code)
		return "", fmt.Errorf("invalid match code")
	}

	// Parse the stored JSON value
	var matchData map[string]string
	if err := json.Unmarshal([]byte(objects[0].Value), &matchData); err != nil {
		logger.Error("Failed to parse match data: %v", err)
		return "", fmt.Errorf("invalid match data")
	}

	matchId := matchData["matchId"]
	if matchId == "" {
		return "", fmt.Errorf("invalid match data")
	}

	response := map[string]string{"matchId": matchId}
	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}

func RPCGetMatchInfo(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req struct {
		Code string `json:"code"`
	}
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		return "", fmt.Errorf("invalid payload")
	}

	// First get the match ID from the code
	objects, err := nk.StorageRead(ctx, []*runtime.StorageRead{{
		Collection: "match_codes",
		Key:        req.Code,
	}})
	if err != nil || len(objects) == 0 {
		logger.Warn("Code not found: %s", req.Code)
		return "", fmt.Errorf("invalid match code")
	}

	// Parse the stored JSON value
	var matchData map[string]string
	if err := json.Unmarshal([]byte(objects[0].Value), &matchData); err != nil {
		logger.Error("Failed to parse match data: %v", err)
		return "", fmt.Errorf("invalid match data")
	}

	matchId := matchData["matchId"]
	if matchId == "" {
		return "", fmt.Errorf("invalid match data")
	}

	// Check if the match actually exists by trying to get its state
	_, err = nk.MatchGet(ctx, matchId)
	if err != nil {
		logger.Warn("Match not found: %s", matchId)
		return "", fmt.Errorf("match not found")
	}

	response := map[string]interface{}{
		"exists":  true,
		"matchId": matchId,
	}
	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}
