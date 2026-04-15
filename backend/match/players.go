package match

import (
	"context"
	"fmt"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
)

// HandlePlayerJoin assigns a symbol and starts the game when both players are in.
func (s *GameService) HandlePlayerJoin(state *MatchState, presence runtime.Presence, tick int64) error {
	if len(state.Players) >= MaxPlayers {
		return fmt.Errorf("match is full")
	}

	symbol := SymbolX
	if len(state.Players) == 1 {
		symbol = SymbolO
	}

	state.Players[presence.GetUserId()] = &PlayerData{
		UserID:      presence.GetUserId(),
		Username:    presence.GetUsername(),
		Symbol:      symbol,
		IsConnected: true,
	}
	s.logger.Info("Player joined: %s as %s", presence.GetUsername(), symbol)

	if len(state.Players) == 1 {
		state.CurrentTurnID = presence.GetUserId()
	}

	if len(state.Players) == MaxPlayers {
		now := time.Now().Unix()
		state.StartTime = now
		state.TurnStartTime = now
		s.broadcastState(state, OpCodeState)
		s.logger.Info("Match ready — starting game")
	}

	return nil
}

// HandlePlayerLeave marks a player as disconnected and awards a forfeit
// win to the opponent if the game was still in progress.
func (s *GameService) HandlePlayerLeave(ctx context.Context, state *MatchState, presence runtime.Presence) {
	player, exists := state.Players[presence.GetUserId()]
	if !exists {
		return
	}

	player.IsConnected = false
	s.logger.Info("Player left: %s", presence.GetUsername())

	if state.GameOver || len(state.Players) < MaxPlayers {
		return
	}

	state.GameOver = true
	for userID, p := range state.Players {
		if p.IsConnected {
			state.Winner = userID
			s.updatePlayerStats(ctx, state, userID, true)
		} else {
			s.updatePlayerStats(ctx, state, userID, false)
		}
	}
	s.broadcastState(state, OpCodeGameEnd)
}
