package match

import (
	"time"
)

// NewGameState creates a blank game state for the given mode.
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

	if mode == ModeTimed {
		state.TurnTimeoutSecs = TurnTimeoutSecs
	}

	return state
}

// IsTimedOut returns true if the current turn has exceeded its time limit.
func (ms *MatchState) IsTimedOut() bool {
	if ms.Mode != ModeTimed || ms.TurnStartTime == 0 {
		return false
	}
	elapsed := time.Now().Unix() - ms.TurnStartTime
	return elapsed > int64(ms.TurnTimeoutSecs)
}

// SwitchTurn advances to the next player and resets the turn clock.
func (ms *MatchState) SwitchTurn(tick int64) {
	for userID := range ms.Players {
		if userID != ms.CurrentTurnID {
			ms.CurrentTurnID = userID
			ms.TurnStartTime = time.Now().Unix()
			return
		}
	}
}
