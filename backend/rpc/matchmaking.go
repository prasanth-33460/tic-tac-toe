package rpc

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"math/rand"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/prasanth-33460/tic-tac-toe/backend/match"
)

// RPCFindMatch creates a new match with the requested mode and returns its
// ID along with a shareable short code.
func RPCFindMatch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	req := parseMatchRequest(payload, logger)

	logger.Info("Finding match — mode: %s, skill: %d", req.Mode, req.SkillLevel)

	params := map[string]interface{}{"mode": req.Mode}
	matchID, err := nk.MatchCreate(ctx, "tictactoe", params)
	if err != nil {
		logger.Error("Match creation failed: %v", err)
		return "", fmt.Errorf("match creation failed")
	}

	shortCode := generateShortCode(nk, ctx, logger)
	if shortCode == "" {
		return "", fmt.Errorf("failed to generate short code")
	}

	// Persist code -> matchID mapping so other players can join by code.
	matchData, _ := json.Marshal(map[string]string{"matchId": matchID})
	_, err = nk.StorageWrite(ctx, []*runtime.StorageWrite{{
		Collection:      "match_codes",
		Key:             shortCode,
		Value:           string(matchData),
		PermissionRead:  2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.Error("Short code storage failed: %v", err)
		return "", fmt.Errorf("storage error")
	}

	return marshalResponse(map[string]interface{}{
		"matchId":   matchID,
		"shortCode": shortCode,
		"mode":      req.Mode,
	}, logger)
}

// RPCCreateQuickMatch creates a match without generating a short code.
func RPCCreateQuickMatch(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	req := parseMatchRequest(payload, logger)

	logger.Info("Quick match — mode: %s", req.Mode)

	params := map[string]interface{}{"mode": req.Mode}
	matchID, err := nk.MatchCreate(ctx, "tictactoe", params)
	if err != nil {
		logger.Error("Match creation failed: %v", err)
		return "", fmt.Errorf("match creation failed")
	}

	return marshalResponse(map[string]interface{}{
		"matchId": matchID,
		"mode":    req.Mode,
	}, logger)
}

// MatchmakerMatched is called by Nakama when two players are matched via
// the built-in matchmaker.
func MatchmakerMatched(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, entries []runtime.MatchmakerEntry) (string, error) {
	if len(entries) != 2 {
		return "", fmt.Errorf("expected 2 players, got %d", len(entries))
	}

	mode := match.ModeClassic
	if props := entries[0].GetProperties(); props != nil {
		if modeStr, ok := props["mode"].(string); ok {
			mode = modeStr
		}
	}

	matchID, err := nk.MatchCreate(ctx, "tictactoe", map[string]interface{}{"mode": mode})
	if err != nil {
		logger.Error("Matchmaker match creation failed: %v", err)
		return "", err
	}

	logger.Info("Matchmaker created match %s for %d players", matchID, len(entries))
	return matchID, nil
}

// RPCGetMatchIdByCode resolves a 6-digit short code to the full match ID.
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

	var matchData map[string]string
	if err := json.Unmarshal([]byte(objects[0].Value), &matchData); err != nil {
		return "", fmt.Errorf("corrupt match data")
	}

	matchId := matchData["matchId"]
	if matchId == "" {
		return "", fmt.Errorf("invalid match data")
	}

	resp, _ := json.Marshal(map[string]string{"matchId": matchId})
	return string(resp), nil
}

// RPCGetMatchInfo checks whether a match exists. Accepts either a direct
// matchId or a short code.
func RPCGetMatchInfo(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var req struct {
		Code    string `json:"code"`
		MatchID string `json:"matchId"`
	}
	if err := json.Unmarshal([]byte(payload), &req); err != nil {
		return "", fmt.Errorf("invalid payload")
	}

	matchId := req.MatchID

	// Resolve short code when no direct ID is given.
	if matchId == "" && req.Code != "" {
		objects, err := nk.StorageRead(ctx, []*runtime.StorageRead{{
			Collection: "match_codes",
			Key:        req.Code,
		}})
		if err != nil || len(objects) == 0 {
			return "", fmt.Errorf("invalid match code")
		}

		var matchData map[string]string
		if err := json.Unmarshal([]byte(objects[0].Value), &matchData); err != nil {
			return "", fmt.Errorf("corrupt match data")
		}
		matchId = matchData["matchId"]
	}

	if matchId == "" {
		return "", fmt.Errorf("matchId or code is required")
	}

	if _, err := nk.MatchGet(ctx, matchId); err != nil {
		logger.Warn("Match not found: %s", matchId)
		return "", fmt.Errorf("match not found")
	}

	resp, _ := json.Marshal(map[string]interface{}{
		"exists":  true,
		"matchId": matchId,
	})
	return string(resp), nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func parseMatchRequest(payload string, logger runtime.Logger) MatchRequest {
	var req MatchRequest
	if payload != "" && payload != "{}" {
		if err := json.Unmarshal([]byte(payload), &req); err != nil {
			logger.Warn("Bad match request payload: %v", err)
		}
	}
	if req.Mode == "" {
		req.Mode = match.ModeClassic
	}
	if req.SkillLevel < 0 || req.SkillLevel > 100 {
		req.SkillLevel = 50
	}
	return req
}

func generateShortCode(nk runtime.NakamaModule, ctx context.Context, logger runtime.Logger) string {
	for i := 0; i < 10; i++ {
		code := fmt.Sprintf("%06d", rand.Intn(1000000))
		objects, err := nk.StorageRead(ctx, []*runtime.StorageRead{{
			Collection: "match_codes",
			Key:        code,
		}})
		if err != nil || len(objects) == 0 {
			return code
		}
	}
	logger.Error("Failed to generate unique short code after 10 attempts")
	return ""
}

func marshalResponse(data interface{}, logger runtime.Logger) (string, error) {
	b, err := json.Marshal(data)
	if err != nil {
		logger.Error("Response marshal failed: %v", err)
		return "", fmt.Errorf("internal error")
	}
	return string(b), nil
}
