package match

import (
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/prasanth-33460/tic-tac-toe/backend/utils"
)

// NewGameService creates the service that all match handler methods delegate to.
func NewGameService(logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher) *GameService {
	return &GameService{
		logger:     logger,
		db:         db,
		nk:         nk,
		dispatcher: dispatcher,
	}
}

// broadcastState serialises the current state and sends it to all players.
func (s *GameService) broadcastState(state *MatchState, opCode int64) {
	stateJSON, err := utils.JsonMarshal(state)
	if err != nil {
		s.logger.Error("Failed to marshal state: %v", err)
		return
	}
	s.dispatcher.BroadcastMessage(opCode, stateJSON, nil, nil, true)
}
