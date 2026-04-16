package match

import (
	"context"
	"fmt"
	"strconv"

	dbpkg "github.com/prasanth-33460/tic-tac-toe/backend/db"
	"github.com/prasanth-33460/tic-tac-toe/backend/utils"
)

// ---------------------------------------------------------------------------
// Join validation
// ---------------------------------------------------------------------------

// ValidateJoinRequest checks bans, skill compatibility, and mode before
// allowing a player into the match.
func (s *GameService) ValidateJoinRequest(ctx context.Context, state *MatchState, userID string, metadata map[string]string) ValidationResult {
	repo := dbpkg.NewRepository(s.db)
	if banned, err := repo.IsPlayerBanned(ctx, userID); err == nil && banned {
		return ValidationResult{Valid: false, Message: "player is banned"}
	}

	playerSkill, matchSkill := getSkillLevels(metadata, state.Metadata)
	if result := validateSkillCompatibility(playerSkill, matchSkill); !result.Valid {
		return result
	}

	if result := validateGameMode(metadata["mode"], state.Mode); !result.Valid {
		return result
	}

	return ValidationResult{Valid: true}
}

func getSkillLevels(playerMeta map[string]string, matchMeta map[string]interface{}) (playerSkill, matchSkill int) {
	if skillStr, ok := playerMeta["skill_level"]; ok {
		if skill, err := strconv.Atoi(skillStr); err == nil {
			playerSkill = skill
		}
	}
	if skill, ok := matchMeta["skill_level"].(float64); ok {
		matchSkill = int(skill)
	}
	return
}

func validateSkillCompatibility(playerSkill, matchSkill int) ValidationResult {
	if playerSkill == 0 || matchSkill == 0 {
		return ValidationResult{Valid: true}
	}

	diff := utils.Abs(playerSkill - matchSkill)
	if diff > MaxSkillDiff {
		return ValidationResult{
			Valid:   false,
			Message: fmt.Sprintf("skill difference too high: %d", diff),
		}
	}
	return ValidationResult{Valid: true}
}

func validateGameMode(playerMode, gameMode string) ValidationResult {
	if playerMode == "" || playerMode == gameMode {
		return ValidationResult{Valid: true}
	}
	return ValidationResult{Valid: false, Message: "game mode mismatch"}
}

// ---------------------------------------------------------------------------
// Move validation
// ---------------------------------------------------------------------------

// ValidateMove checks whether a player's move is legal.
func ValidateMove(state *MatchState, userID string, position int) error {
	if state.GameOver {
		return fmt.Errorf("game has already ended")
	}

	if state.CurrentTurnID != userID {
		return fmt.Errorf("not your turn")
	}

	if _, exists := state.Players[userID]; !exists {
		return fmt.Errorf("player not in match")
	}

	if position < 0 || position >= BoardSize {
		return fmt.Errorf("position out of bounds: %d", position)
	}

	if state.Board[position] != "" {
		return fmt.Errorf("position already occupied")
	}

	return nil
}

// CheckWinner scans the board for a three-in-a-row or a full board draw.
func CheckWinner(state *MatchState) (winner string, isDraw bool) {
	for _, pattern := range WinPatterns {
		a, b, c := state.Board[pattern[0]], state.Board[pattern[1]], state.Board[pattern[2]]

		if a != "" && a == b && b == c {
			for userID, player := range state.Players {
				if player.Symbol == a {
					return userID, false
				}
			}
		}
	}

	if state.MoveCount >= BoardSize {
		return "", true
	}

	return "", false
}
