package match

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	dbpkg "github.com/prasanth-33460/tic-tac-toe/backend/db"
	"github.com/prasanth-33460/tic-tac-toe/backend/utils"
)

// HandleSignal routes a client signal to the appropriate handler.
func (s *GameService) HandleSignal(ctx context.Context, state *MatchState, userID string, data string) (string, error) {
	var signalData map[string]any
	if err := utils.JsonUnmarshal([]byte(data), &signalData); err != nil {
		return "", fmt.Errorf("invalid signal data: %v", err)
	}

	signalType, ok := signalData["type"].(string)
	if !ok {
		return "", fmt.Errorf("missing signal type")
	}

	switch signalType {
	case "rematch_request":
		return s.handleRematchRequest(state)
	case "chat_message":
		return s.handleChatMessage(ctx, state, userID, signalData)
	default:
		return "", fmt.Errorf("unknown signal type: %s", signalType)
	}
}

func (s *GameService) handleRematchRequest(state *MatchState) (string, error) {
	if !state.GameOver {
		return "", fmt.Errorf("game is still in progress")
	}

	state.Board = [BoardSize]string{}
	state.GameOver = false
	state.Winner = ""
	state.IsDraw = false
	state.MoveCount = 0

	for id := range state.Players {
		if id != state.CurrentTurnID {
			state.CurrentTurnID = id
			break
		}
	}

	state.TurnStartTime = time.Now().Unix()
	s.broadcastState(state, OpCodeState)
	return "rematch_accepted", nil
}

func (s *GameService) handleChatMessage(ctx context.Context, state *MatchState, userID string, data map[string]any) (string, error) {
	message, ok := data["message"].(string)
	if !ok {
		return "", fmt.Errorf("missing message content")
	}
	if len(message) == 0 || len(message) > MaxChatLength {
		return "", fmt.Errorf("message must be between 1-%d characters", MaxChatLength)
	}

	player, ok := state.Players[userID]
	if !ok {
		return "", fmt.Errorf("player not found")
	}

	chatPayload, _ := json.Marshal(map[string]any{
		"type":      "chat",
		"sender":    player.Username,
		"message":   message,
		"timestamp": time.Now().Unix(),
	})

	s.dispatcher.BroadcastMessage(OpCodeChat, chatPayload, nil, nil, true)

	repo := dbpkg.NewRepository(s.db)
	if err := repo.InsertChatMessage(ctx, userID, player.Username, message); err != nil {
		s.logger.Error("Failed to persist chat: %v", err)
	}
	return "message_sent", nil
}
