package match

import (
	"time"
)

// NewGameState creates a fresh game state with the specified mode
func NewGameState(mode string) *MatchState {
	state := &MatchState{
		Board:           [BoardSize]string{},
		Players:         make(map[string]*PlayerData),
		Mode:            mode,
		TurnTimeoutSecs: 0,
		MoveCount:       0,
		Metadata:        make(map[string]interface{}),
		Preferences:     make(map[string]string),
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
