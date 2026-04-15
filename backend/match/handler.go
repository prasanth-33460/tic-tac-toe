package match

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/heroiclabs/nakama-common/runtime"
)

// MatchInit sets up a new match with the requested game mode.
func (m *Match) MatchInit(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, params map[string]interface{}) (interface{}, int, string) {
	mode := ModeClassic
	if modeParam, ok := params["mode"].(string); ok && modeParam == ModeTimed {
		mode = ModeTimed
	}

	state := NewGameState(mode)
	label := fmt.Sprintf("mode:%s", mode)

	logger.Info("Match initialized — mode: %s", mode)
	return state, TickRate, label
}

// MatchJoinAttempt decides whether a player is allowed to join.
func (m *Match) MatchJoinAttempt(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presence runtime.Presence, metadata map[string]string) (interface{}, bool, string) {
	gameState := state.(*MatchState)
	m.ensureService(logger, db, nk, dispatcher)

	if len(gameState.Players) >= MaxPlayers {
		return state, false, "match is full"
	}

	result := m.service.ValidateJoinRequest(ctx, gameState, presence.GetUserId(), metadata)
	if !result.Valid {
		return state, false, result.Message
	}

	if gameState.MoveCount > 0 {
		return state, false, "game in progress"
	}

	return state, true, ""
}

// MatchJoin registers a newly joined player into the game state.
func (m *Match) MatchJoin(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
	gameState := state.(*MatchState)
	m.ensureService(logger, db, nk, dispatcher)

	// Capture the match ID so we can reference it later (e.g. history).
	if gameState.MatchID == "" {
		if matchID, ok := ctx.Value(runtime.RUNTIME_CTX_MATCH_ID).(string); ok {
			gameState.MatchID = matchID
		}
	}

	for _, presence := range presences {
		if err := m.service.HandlePlayerJoin(gameState, presence, tick); err != nil {
			logger.Error("Player join failed: %v", err)
		}
	}

	return gameState
}

// MatchLeave handles a player disconnecting mid-game.
func (m *Match) MatchLeave(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
	gameState := state.(*MatchState)
	m.ensureService(logger, db, nk, dispatcher)

	for _, presence := range presences {
		m.service.HandlePlayerLeave(ctx, gameState, presence)
	}

	return gameState
}

// MatchLoop runs every tick — processes moves and checks timeouts.
func (m *Match) MatchLoop(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, messages []runtime.MatchData) interface{} {
	gameState := state.(*MatchState)
	m.ensureService(logger, db, nk, dispatcher)

	// Auto-move on timeout in timed mode.
	if gameState.Mode == ModeTimed && !gameState.GameOver && len(gameState.Players) == MaxPlayers {
		if gameState.IsTimedOut() {
			m.service.HandleTimeout(ctx, gameState)
			return gameState
		}
	}

	for _, message := range messages {
		switch message.GetOpCode() {
		case OpCodeMove:
			var move MoveMessage
			if err := json.Unmarshal(message.GetData(), &move); err != nil {
				logger.Error("Bad move payload: %v", err)
				continue
			}
			if err := m.service.ProcessMove(ctx, gameState, message.GetUserId(), move.Position, tick); err != nil {
				logger.Error("Move processing failed: %v", err)
			}

		case OpCodeChat:
			var chatData map[string]any
			if err := json.Unmarshal(message.GetData(), &chatData); err != nil {
				logger.Error("Bad chat payload: %v", err)
				continue
			}
			if _, err := m.service.handleChatMessage(ctx, gameState, message.GetUserId(), chatData); err != nil {
				logger.Error("Chat handling failed: %v", err)
			}
		}
	}

	return gameState
}

// MatchTerminate is called when the server shuts the match down.
func (m *Match) MatchTerminate(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, graceSeconds int) interface{} {
	logger.Info("Match terminated")
	return state
}

// MatchSignal handles custom client-to-server signals (rematch, chat, etc.).
func (m *Match) MatchSignal(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, data string) (interface{}, string) {
	m.ensureService(logger, db, nk, dispatcher)

	gameState := state.(*MatchState)

	var signalData struct {
		UserID string `json:"userId"`
		Type   string `json:"type"`
	}
	if err := json.Unmarshal([]byte(data), &signalData); err != nil {
		logger.Error("Bad signal payload: %v", err)
		return state, fmt.Sprintf("error: %v", err)
	}

	if signalData.UserID == "" {
		return state, "error: missing userId"
	}

	result, err := m.service.HandleSignal(ctx, gameState, signalData.UserID, data)
	if err != nil {
		logger.Error("Signal handling failed: %v", err)
		return state, fmt.Sprintf("error: %v", err)
	}

	return state, result
}

// ensureService lazily initialises the GameService (needed because the-dispatcher isn't available until the first handler call after MatchInit).
func (m *Match) ensureService(logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher) {
	if m.service == nil {
		m.service = NewGameService(logger, db, nk, dispatcher)
	}
}
