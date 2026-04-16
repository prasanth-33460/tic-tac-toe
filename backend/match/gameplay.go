package match

import (
	"context"
	"fmt"
)

// ProcessMove validates a move, applies it, checks for a winner, and broadcasts the updated state.
func (s *GameService) ProcessMove(ctx context.Context, state *MatchState, userID string, position int, tick int64) error {
	if err := ValidateMove(state, userID, position); err != nil {
		return err
	}

	player, exists := state.Players[userID]
	if !exists {
		return fmt.Errorf("player not in match: %s", userID)
	}

	state.Board[position] = player.Symbol
	state.MoveCount++
	s.logger.Info("Move: %s placed %s at %d", player.Username, player.Symbol, position)

	winner, isDraw := CheckWinner(state)
	if winner != "" || isDraw {
		s.finishGame(ctx, state, winner, isDraw)
	} else {
		state.SwitchTurn(tick)
		s.broadcastState(state, OpCodeState)
	}

	return nil
}

// HandleTimeout makes an automatic move for the timed-out player.
func (s *GameService) HandleTimeout(ctx context.Context, state *MatchState) {
	player, exists := state.Players[state.CurrentTurnID]
	if !exists {
		s.logger.Error("Timeout for unknown player: %s", state.CurrentTurnID)
		return
	}
	s.logger.Info("Timeout for %s — auto-moving", player.Username)

	autoPos := findFirstEmptyCell(state)
	if autoPos == -1 {
		s.logger.Error("No available positions for auto-move")
		return
	}

	state.Board[autoPos] = player.Symbol
	state.MoveCount++
	s.logger.Info("Auto-move: %s at %d", player.Symbol, autoPos)

	winner, isDraw := CheckWinner(state)
	if winner != "" || isDraw {
		s.finishGame(ctx, state, winner, isDraw)
	} else {
		state.SwitchTurn(0)
		s.broadcastState(state, OpCodeState)
	}
}

// finishGame sets game-over flags, updates stats, records history, and broadcasts.
func (s *GameService) finishGame(ctx context.Context, state *MatchState, winner string, isDraw bool) {
	state.GameOver = true
	state.Winner = winner
	state.IsDraw = isDraw

	for playerID := range state.Players {
		s.updatePlayerStats(ctx, state, playerID, playerID == winner)
	}

	s.recordMatchHistory(ctx, state)
	s.broadcastState(state, OpCodeGameEnd)
	s.logger.Info("Game ended — winner: %s, draw: %v", winner, isDraw)
}

func findFirstEmptyCell(state *MatchState) int {
	for i := 0; i < BoardSize; i++ {
		if state.Board[i] == "" {
			return i
		}
	}
	return -1
}
