package match

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
)

// NewGameService creates a new game service instance
func NewGameService(logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher) *GameService {
	return &GameService{
		logger:     logger,
		db:         db,
		nk:         nk,
		dispatcher: dispatcher,
	}
}

// ValidateJoinRequest validates if a player can join a match based on various criteria
func (s *GameService) ValidateJoinRequest(ctx context.Context, state *MatchState, userID string, metadata map[string]string) ValidationResult {
	// Check if banned
	if banned, err := s.IsPlayerBanned(ctx, userID); err == nil && banned {
		return ValidationResult{Valid: false, Message: "player is banned"}
	}

	// Check skill level compatibility
	playerSkill, matchSkill := s.getSkillLevels(metadata, state.Metadata)
	if result := s.validateSkillCompatibility(playerSkill, matchSkill); !result.Valid {
		return result
	}

	// Check game mode compatibility
	if result := s.validateGameMode(metadata["mode"], state.Mode); !result.Valid {
		return result
	}

	return ValidationResult{Valid: true}
}

// IsPlayerBanned checks if a player is banned from matchmaking
func (s *GameService) IsPlayerBanned(ctx context.Context, userID string) (bool, error) {
	var banned bool
	query := "SELECT is_banned FROM player_status WHERE user_id = $1"
	err := s.db.QueryRowContext(ctx, query, userID).Scan(&banned)

	if err == sql.ErrNoRows {
		return false, nil
	}

	return banned, err
}

// getSkillLevels extracts skill levels from metadata
func (s *GameService) getSkillLevels(playerMeta map[string]string, matchMeta map[string]interface{}) (playerSkill, matchSkill int) {
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

// validateSkillCompatibility checks if skill levels are compatible
func (s *GameService) validateSkillCompatibility(playerSkill, matchSkill int) ValidationResult {
	if playerSkill == 0 || matchSkill == 0 {
		return ValidationResult{Valid: true}
	}

	maxSkillDiff := 20 // Configurable threshold
	diff := abs(playerSkill - matchSkill)
	if diff > maxSkillDiff {
		return ValidationResult{
			Valid:   false,
			Message: fmt.Sprintf("skill difference too high: %d", diff),
		}
	}

	return ValidationResult{Valid: true}
}

// validateGameMode checks if game modes are compatible
func (s *GameService) validateGameMode(playerMode, gameMode string) ValidationResult {
	if playerMode == "" {
		return ValidationResult{Valid: true}
	}

	if playerMode != gameMode {
		return ValidationResult{
			Valid:   false,
			Message: "game mode mismatch",
		}
	}

	return ValidationResult{Valid: true}
}

// abs returns the absolute value of an integer
func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

// ProcessMove handles a player's move
func (s *GameService) ProcessMove(ctx context.Context, state *MatchState, userID string, position int) error {
	if err := ValidateMove(state, userID, position); err != nil {
		return err
	}

	player := state.Players[userID]
	state.Board[position] = player.Symbol
	state.MoveCount++

	s.logger.Info("Move processed: %s placed %s at position %d", player.Username, player.Symbol, position)

	winner, isDraw := CheckWinner(state)
	if winner != "" || isDraw {
		state.GameOver = true
		state.Winner = winner
		state.IsDraw = isDraw

		// Update stats for both players
		for playerID := range state.Players {
			isWinner := playerID == winner
			s.updatePlayerStats(ctx, state, playerID, isWinner)
		}

		s.broadcastState(state, OpCodeGameEnd)
		s.logger.Info("Game ended - Winner: %s, Draw: %v", winner, isDraw)
	} else {
		state.SwitchTurn()
		s.broadcastState(state, OpCodeState)
	}

	return nil
}

// HandleTimeout processes turn timeout in timed mode
func (s *GameService) HandleTimeout(ctx context.Context, state *MatchState) {
	s.logger.Info("Turn timeout for player: %s", state.CurrentTurnID)

	state.GameOver = true

	// Other player wins by timeout
	for userID := range state.Players {
		if userID != state.CurrentTurnID {
			state.Winner = userID
			s.updatePlayerStats(ctx, state, userID, true)
		} else {
			s.updatePlayerStats(ctx, state, userID, false)
		}
	}

	s.broadcastState(state, OpCodeTimeout)
}

// HandlePlayerJoin processes a new player joining the game
func (s *GameService) HandlePlayerJoin(state *MatchState, presence runtime.Presence, tick int64) error {
	if len(state.Players) >= MaxPlayers {
		return fmt.Errorf("match is full")
	}

	symbol := "X"
	if len(state.Players) == 1 {
		symbol = "O"
	}

	player := &PlayerData{
		UserID:      presence.GetUserId(),
		Username:    presence.GetUsername(),
		Symbol:      symbol,
		IsConnected: true,
	}

	state.Players[presence.GetUserId()] = player
	s.logger.Info("Player joined: %s as %s", presence.GetUsername(), symbol)

	if len(state.Players) == 1 {
		state.CurrentTurnID = presence.GetUserId()
		state.TurnStartTime = tick
	}

	if len(state.Players) == MaxPlayers {
		s.broadcastState(state, OpCodeState)
		s.logger.Info("Match ready, starting game")
	}

	return nil
}

// HandlePlayerLeave processes a player leaving the game
func (s *GameService) HandlePlayerLeave(ctx context.Context, state *MatchState, presence runtime.Presence) {
	if player, exists := state.Players[presence.GetUserId()]; exists {
		player.IsConnected = false
		s.logger.Info("Player left: %s", presence.GetUsername())

		// If game is in progress, other player wins by forfeit
		if !state.GameOver && len(state.Players) == MaxPlayers {
			state.GameOver = true

			// Find remaining player
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
	}
}

// HandleSignal processes custom signals from clients
func (s *GameService) HandleSignal(ctx context.Context, state *MatchState, userID string, data string) (string, error) {
	var signalData map[string]interface{}
	if err := json.Unmarshal([]byte(data), &signalData); err != nil {
		return "", fmt.Errorf("invalid signal data: %v", err)
	}

	signalType, ok := signalData["type"].(string)
	if !ok {
		return "", fmt.Errorf("missing signal type")
	}

	switch signalType {
	case "rematch_request":
		return s.handleRematchRequest(ctx, state, userID)
	case "chat_message":
		return s.handleChatMessage(ctx, state, userID, signalData)
	default:
		return "", fmt.Errorf("unknown signal type: %s", signalType)
	}
}

func (s *GameService) handleRematchRequest(ctx context.Context, state *MatchState, userID string) (string, error) {
	if !state.GameOver {
		return "", fmt.Errorf("game is still in progress")
	}

	// Reset game state but keep players
	state.Board = [BoardSize]string{}
	state.GameOver = false
	state.Winner = ""
	state.IsDraw = false
	state.MoveCount = 0

	// Switch first turn to the other player
	for id := range state.Players {
		if id != state.CurrentTurnID {
			state.CurrentTurnID = id
			break
		}
	}

	s.broadcastState(state, OpCodeState)
	return "rematch_accepted", nil
}

func (s *GameService) handleChatMessage(ctx context.Context, state *MatchState, userID string, data map[string]interface{}) (string, error) {
	message, ok := data["message"].(string)
	if !ok {
		return "", fmt.Errorf("missing message content")
	}

	if player, ok := state.Players[userID]; ok {
		chatData := map[string]interface{}{
			"type":      "chat",
			"sender":    player.Username,
			"message":   message,
			"timestamp": time.Now().Unix(),
		}

		chatJSON, _ := json.Marshal(chatData)
		s.dispatcher.BroadcastMessage(OpCodeChat, chatJSON, nil, nil, true)
		return "message_sent", nil
	}

	return "", fmt.Errorf("player not found")
}

// updatePlayerStats updates leaderboards and player records
func (s *GameService) updatePlayerStats(ctx context.Context, state *MatchState, userID string, won bool) {
	player := state.Players[userID]

	if won {
		player.Wins++

		// Increment wins leaderboard
		_, err := s.nk.LeaderboardRecordWrite(ctx, "global_wins", userID, player.Username, 1, 0, nil, nil)
		if err != nil {
			s.logger.Error("Failed to update wins leaderboard: %v", err)
		}

		// Update win streak
		_, err = s.nk.LeaderboardRecordWrite(ctx, "win_streaks", userID, player.Username, int64(player.Wins), 0, nil, nil)
		if err != nil {
			s.logger.Error("Failed to update streak leaderboard: %v", err)
		}
	} else if !state.IsDraw {
		player.Losses++
	}
}

// broadcastState sends current game state to all connected players
func (s *GameService) broadcastState(state *MatchState, opCode int64) {
	stateJSON, err := json.Marshal(state)
	if err != nil {
		s.logger.Error("Failed to marshal game state: %v", err)
		return
	}

	s.dispatcher.BroadcastMessage(opCode, stateJSON, nil, nil, true)
}
