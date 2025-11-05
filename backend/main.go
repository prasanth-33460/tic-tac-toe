package main

import (
	"context"
	"database/sql"
	"encoding/json"

	"github.com/heroiclabs/nakama-common/runtime"
)

func Init(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {
	logger.Info("model initialising.")

	err := initializer.RegisterMatch("tic-tac-toe", func(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule) (runtime.Match, error) {
		return &Match{}, nil
	})

	if err != nil {
		logger.Error("Failed to register match: %v", err)
		return err
	}

	logger.Info("Match handler registered!")
	return nil
}

type Match struct {
	Board [9]string //3x3 board tic-tac-toe.
}

type MatchState struct {
	Board         [9]string
	Players       map[string]*PlayerData // mapping userId to player
	CurrentTurnID string                 // whose turn is it?
	GameOver      bool
	Winner        string
}

type PlayerData struct {
	UserID   string
	Username string
	Symbol   string // either x or o.
}

func (m *Match) MatchInit(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, params map[string]interface{}) (interface{}, int, string) {
	state := &MatchState{
		Board:   [9]string{"", "", "", "", "", "", "", "", ""},
		Players: make(map[string]*PlayerData),
	} // Define custom MatchState in the code as per your game's requirements
	logger.Info("Match created with empty board")
	tickRate := 1            // Call MatchLoop() every 1s.
	label := "skill=100-150" // Custom label that will be used to filter match listings.

	return state, tickRate, label
}

func (m *Match) MatchJoin(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
	// Custom code to process match join and send updated state to a joining or re-joining user.
	matchState := state.(*MatchState)
	for _, presence := range presences {
		// In xo, first player is always x.
		symbol := "X"
		if len(matchState.Players) == 1 {
			symbol = "O"
		}

		player := &PlayerData{
			UserID:   presence.GetUserId(),
			Username: presence.GetUsername(),
			Symbol:   symbol,
		}

		matchState.Players[presence.GetUserId()] = player
		logger.Info("Player %s joined as %s", player.Username, symbol)
		if len(matchState.Players) == 1 {
			matchState.CurrentTurnID = presence.GetUserId()
			logger.Info("It's %s's turn first", player.Username)
		}
	}

	return state
}

func (m *Match) MatchJoinAttempt(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presence runtime.Presence, metadata map[string]string) (interface{}, bool, string) {
	result := true

	// Custom code to process match join attempt.
	return state, result, ""
}

func (m *Match) MatchLeave(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
	// Custom code to handle a disconnected/leaving user.
	return state
}

func (m *Match) MatchLoop(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, messages []runtime.MatchData) interface{} {
	// Custom code to:
	// - Process the messages received.
	// - Update the match state based on the messages and time elapsed.
	// - Broadcast new data messages to match participants.
	gameState := state.(*MatchState)

	for _, message := range messages {
		if message.GetOpCode() == 1 {

			userID := message.GetUserId()
			data := message.GetData()

			var moveData map[string]interface{}
			json.Unmarshal(data, &moveData)

			position := int(moveData["position"].(float64))

			logger.Info("Player %s wants to move at position %d", userID, position)

			if !m.validateMove(gameState, userID, position) {
				logger.Warn("Invalid move!")
				continue
			}

			player := gameState.Players[userID]
			gameState.Board[position] = player.Symbol

			logger.Info("Move applied: %s at %d", player.Symbol, position)

			if winner := m.checkWinner(gameState); winner != "" {
				gameState.GameOver = true
				gameState.Winner = winner
				logger.Info("Game over! Winner: %s", winner)
			} else {
				m.switchTurn(gameState)
			}

			stateJSON, _ := json.Marshal(gameState)
			dispatcher.BroadcastMessage(2, stateJSON, nil, nil, true)
		}
	}
	return state
}

func (m *Match) validateMove(state *MatchState, userID string, position int) bool {
	if state.GameOver {
		return false
	}

	if state.CurrentTurnID != userID {
		return false
	}

	if position < 0 || position > 8 {
		return false
	}

	if state.Board[position] != "" {
		return false
	}

	return true
}

func (m *Match) checkWinner(state *MatchState) string {
	winLines := [][]int{
		{0, 1, 2}, {3, 4, 5}, {6, 7, 8}, // rows
		{0, 3, 6}, {1, 4, 7}, {2, 5, 8}, // columns
		{0, 4, 8}, {2, 4, 6}, // diagonals
	}

	for _, line := range winLines {
		a, b, c := line[0], line[1], line[2]

		if state.Board[a] != "" &&
			state.Board[a] == state.Board[b] &&
			state.Board[b] == state.Board[c] {

			symbol := state.Board[a]
			for userID, player := range state.Players {
				if player.Symbol == symbol {
					return userID
				}
			}
		}
	}
	return ""
}

func (m *Match) switchTurn(state *MatchState) {
	for userID := range state.Players {
		if userID != state.CurrentTurnID {
			state.CurrentTurnID = userID
			return
		}
	}
}

func (m *Match) MatchTerminate(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, graceSeconds int) interface{} {
	// Custom code to process the termination of match.
	return state
}

func (m *Match) MatchSignal(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, data string) (interface{}, string) {
	return state, "signal received: " + data
}
