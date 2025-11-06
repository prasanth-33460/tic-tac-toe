package match

import (
	"time"
)

// MatchState represents the complete state of a tic-tac-toe match
type MatchState struct {
	Board           [BoardSize]string      `json:"board"`
	Players         map[string]*PlayerData `json:"players"`
	CurrentTurnID   string                 `json:"current_turn_id"`
	Winner          string                 `json:"winner"`
	GameOver        bool                   `json:"game_over"`
	IsDraw          bool                   `json:"is_draw"`
	Mode            string                 `json:"mode"`
	TurnStartTime   int64                  `json:"turn_start_time"`
	TurnTimeoutSecs int                    `json:"turn_timeout_secs"`
	MoveCount       int                    `json:"move_count"`
}

// PlayerData contains information about each player in the match
type PlayerData struct {
	UserID      string `json:"user_id"`
	Username    string `json:"username"`
	Symbol      string `json:"symbol"`
	IsConnected bool   `json:"is_connected"`
	Wins        int    `json:"wins"`
	Losses      int    `json:"losses"`
}

// MoveMessage represents a player's move attempt
type MoveMessage struct {
	Position int `json:"position"`
}

// NewGameState creates a fresh game state with the specified mode
func NewGameState(mode string) *MatchState {
	state := &MatchState{
		Board:           [BoardSize]string{},
		Players:         make(map[string]*PlayerData),
		Mode:            mode,
		TurnTimeoutSecs: 0,
		MoveCount:       0,
	}

	// Initialize empty board
	for i := range state.Board {
		state.Board[i] = ""
	}

	// Set timeout for timed mode
	if mode == ModeTimed {
		state.TurnTimeoutSecs = TurnTimeoutSecs
	}

	return state
}

// IsTimedOut checks if the current turn has exceeded the time limit
func (ms *MatchState) IsTimedOut() bool {
	if ms.Mode != ModeTimed || ms.TurnStartTime == 0 {
		return false
	}

	elapsed := time.Now().Unix() - ms.TurnStartTime
	return elapsed > int64(ms.TurnTimeoutSecs)
}

// SwitchTurn changes the active player
func (ms *MatchState) SwitchTurn() {
	for userID := range ms.Players {
		if userID != ms.CurrentTurnID {
			ms.CurrentTurnID = userID
			ms.TurnStartTime = time.Now().Unix()
			return
		}
	}
}
