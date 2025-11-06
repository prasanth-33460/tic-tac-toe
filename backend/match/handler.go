package match

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/heroiclabs/nakama-common/runtime"
)

// MatchInit initializes a new match instance
func (m *Match) MatchInit(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, params map[string]interface{}) (interface{}, int, string) {
	// Extract game mode from params, default to classic
	mode := ModeClassic
	if modeParam, ok := params["mode"].(string); ok {
		if modeParam == ModeTimed {
			mode = ModeTimed
		}
	}

	state := NewGameState(mode)

	// Create match label for matchmaking
	label := fmt.Sprintf("mode:%s", mode)

	logger.Info("Match initialized with mode: %s", mode)

	return state, TickRate, label
}

// MatchJoinAttempt decides if a player can join the match
func (m *Match) MatchJoinAttempt(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presence runtime.Presence, metadata map[string]string) (interface{}, bool, string) {
	gameState := state.(*MatchState)

	if m.service == nil {
		m.service = NewGameService(logger, db, nk, dispatcher)
	}

	// Reject if match is full
	if len(gameState.Players) >= MaxPlayers {
		return state, false, "match is full"
	}

	// Validate join request using service layer
	result := m.service.ValidateJoinRequest(ctx, gameState, presence.GetUserId(), metadata)
	if !result.Valid {
		return state, false, result.Message
	}

	// Reject if game already started
	if gameState.MoveCount > 0 {
		return state, false, "game in progress"
	}

	return state, true, ""
}

// MatchJoin handles a player joining the match
func (m *Match) MatchJoin(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
	gameState := state.(*MatchState)

	if m.service == nil {
		m.service = NewGameService(logger, db, nk, dispatcher)
	}

	for _, presence := range presences {
		if err := m.service.HandlePlayerJoin(gameState, presence, tick); err != nil {
			logger.Error("Failed to handle player join: %v", err)
		}
	}

	return gameState
}

// MatchLeave handles a player leaving the match
func (m *Match) MatchLeave(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
	gameState := state.(*MatchState)

	if m.service == nil {
		m.service = NewGameService(logger, db, nk, dispatcher)
	}

	for _, presence := range presences {
		m.service.HandlePlayerLeave(ctx, gameState, presence)
	}

	return gameState
}

// MatchLoop is called every tick to update the match
func (m *Match) MatchLoop(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, messages []runtime.MatchData) interface{} {
	gameState := state.(*MatchState)

	if m.service == nil {
		m.service = NewGameService(logger, db, nk, dispatcher)
	}

	// Handle timeout in timed mode
	if gameState.Mode == ModeTimed && !gameState.GameOver && len(gameState.Players) == MaxPlayers {
		if gameState.IsTimedOut() {
			m.service.HandleTimeout(ctx, gameState)
			return gameState
		}
	}

	// Process player moves
	for _, message := range messages {
		if message.GetOpCode() == OpCodeMove {
			var move MoveMessage
			if err := json.Unmarshal(message.GetData(), &move); err != nil {
				logger.Error("Failed to unmarshal move: %v", err)
				continue
			}

			if err := m.service.ProcessMove(ctx, gameState, message.GetUserId(), move.Position, tick); err != nil {
				logger.Error("Failed to process move: %v", err)
			}
		}
	}

	return gameState
}

// MatchTerminate is called when the match is shutting down
func (m *Match) MatchTerminate(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, graceSeconds int) interface{} {
	logger.Info("Match terminated")
	return state
}

// MatchSignal handles client-sent signals
func (m *Match) MatchSignal(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, data string) (interface{}, string) {
	if m.service == nil {
		m.service = NewGameService(logger, db, nk, dispatcher)
	}

	gameState := state.(*MatchState)
	var signalData struct {
		UserID string `json:"userId"`
		Type   string `json:"type"`
	}

	if err := json.Unmarshal([]byte(data), &signalData); err != nil {
		logger.Error("Failed to unmarshal signal data: %v", err)
		return state, fmt.Sprintf("error: %v", err)
	}

	if signalData.UserID == "" {
		logger.Error("Missing userId in signal data")
		return state, "error: missing userId"
	}

	result, err := m.service.HandleSignal(ctx, gameState, signalData.UserID, data)
	if err != nil {
		logger.Error("Failed to handle signal: %v", err)
		return state, fmt.Sprintf("error: %v", err)
	}

	return state, result
}
