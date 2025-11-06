package match

import (
	"fmt"
)

// ValidateMove checks if a player's move is legal
func ValidateMove(state *MatchState, userID string, position int) error {
	// Check if game is already over
	if state.GameOver {
		return fmt.Errorf("game has already ended")
	}

	// Verify it's the player's turn
	if state.CurrentTurnID != userID {
		return fmt.Errorf("not your turn")
	}

	// Check if player exists in the match
	if _, exists := state.Players[userID]; !exists {
		return fmt.Errorf("player not in match")
	}

	// Validate position bounds
	if position < 0 || position >= BoardSize {
		return fmt.Errorf("position out of bounds: %d", position)
	}

	// Check if position is already occupied
	if state.Board[position] != "" {
		return fmt.Errorf("position already occupied")
	}

	return nil
}

// CheckWinner analyzes the board for a winning condition
func CheckWinner(state *MatchState) (winner string, isDraw bool) {
	// Check all winning patterns
	for _, pattern := range WinPatterns {
		if state.Board[pattern[0]] != "" &&
			state.Board[pattern[0]] == state.Board[pattern[1]] &&
			state.Board[pattern[1]] == state.Board[pattern[2]] {

			// Found a winner - determine which player
			symbol := state.Board[pattern[0]]
			for userID, player := range state.Players {
				if player.Symbol == symbol {
					return userID, false
				}
			}
		}
	}

	// Check for draw (all positions filled, no winner)
	if state.MoveCount >= BoardSize {
		return "", true
	}

	return "", false
}
