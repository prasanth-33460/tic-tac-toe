package match

import (
	"time"
)

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

	for i := range state.Board {
		state.Board[i] = ""
	}

	if mode == ModeTimed {
		state.TurnTimeoutSecs = TurnTimeoutSecs
	}

	return state
}

func (ms *MatchState) IsTimedOut() bool {
	if ms.Mode != ModeTimed || ms.TurnStartTime == 0 {
		return false
	}

	elapsed := time.Now().Unix() - ms.TurnStartTime
	return elapsed > int64(ms.TurnTimeoutSecs)
}

func (ms *MatchState) SwitchTurn(tick int64) {
	for userID := range ms.Players {
		if userID != ms.CurrentTurnID {
			ms.CurrentTurnID = userID
			ms.TurnStartTime = tick
			return
		}
	}
}
