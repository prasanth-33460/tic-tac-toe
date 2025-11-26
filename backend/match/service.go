package match

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
	dbpkg "github.com/prasanth-33460/tic-tac-toe/backend/db"
	"github.com/prasanth-33460/tic-tac-toe/backend/utils"
)

func NewGameService(logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher) *GameService {
	return &GameService{
		logger:     logger,
		db:         db,
		nk:         nk,
		dispatcher: dispatcher,
	}
}

func (s *GameService) ValidateJoinRequest(ctx context.Context, state *MatchState, userID string, metadata map[string]string) ValidationResult {
	if banned, err := s.IsPlayerBanned(ctx, userID); err == nil && banned {
		return ValidationResult{Valid: false, Message: "player is banned"}
	}

	playerSkill, matchSkill := s.getSkillLevels(metadata, state.Metadata)
	if result := s.validateSkillCompatibility(playerSkill, matchSkill); !result.Valid {
		return result
	}

	if result := s.validateGameMode(metadata["mode"], state.Mode); !result.Valid {
		return result
	}

	return ValidationResult{Valid: true}
}

func (s *GameService) IsPlayerBanned(ctx context.Context, userID string) (bool, error) {
	var banned bool
	query := "SELECT is_banned FROM player_status WHERE user_id = $1"
	err := s.db.QueryRowContext(ctx, query, userID).Scan(&banned)

	if err == sql.ErrNoRows {
		return false, nil
	}

	return banned, err
}

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

func (s *GameService) validateSkillCompatibility(playerSkill, matchSkill int) ValidationResult {
	if playerSkill == 0 || matchSkill == 0 {
		return ValidationResult{Valid: true}
	}

	maxSkillDiff := 20
	diff := utils.Abs(playerSkill - matchSkill)
	if diff > maxSkillDiff {
		return ValidationResult{
			Valid:   false,
			Message: fmt.Sprintf("skill difference too high: %d", diff),
		}
	}

	return ValidationResult{Valid: true}
}

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

// ProcessMove handles a player's move
func (s *GameService) ProcessMove(ctx context.Context, state *MatchState, userID string, position int, tick int64) error {
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

		s.recordMatchHistory(ctx, state)

		s.broadcastState(state, OpCodeGameEnd)
		s.logger.Info("Game ended - Winner: %s, Draw: %v", winner, isDraw)
	} else {
		state.SwitchTurn(tick)
		s.broadcastState(state, OpCodeState)
	}

	return nil
}

// HandleTimeout processes turn timeout in timed mode
func (s *GameService) HandleTimeout(ctx context.Context, state *MatchState) {
	s.logger.Info("Turn timeout for player: %s - making automatic move", state.CurrentTurnID)

	player := state.Players[state.CurrentTurnID]

	// Find first available position for automatic move
	autoPosition := -1
	for i := 0; i < BoardSize; i++ {
		if state.Board[i] == "" {
			autoPosition = i
			break
		}
	}

	if autoPosition == -1 {
		// Board is full - this shouldn't happen in timeout, but just in case
		s.logger.Error("No available positions for automatic move")
		return
	}

	// Make the automatic move
	state.Board[autoPosition] = player.Symbol
	state.MoveCount++

	s.logger.Info("Automatic move: %s placed %s at position %d (timeout)", player.Username, player.Symbol, autoPosition)

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

		s.recordMatchHistory(ctx, state)

		s.broadcastState(state, OpCodeGameEnd)
		s.logger.Info("Game ended by timeout auto-move - Winner: %s, Draw: %v", winner, isDraw)
	} else {
		// Continue game - switch to next player
		state.SwitchTurn(0) // tick not needed since we use Unix time
		s.broadcastState(state, OpCodeState)
		s.logger.Info("Timeout auto-move completed, continuing game")
	}
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
		Wins:        0,
		Losses:      0,
		Streak:      0,
	}

	state.Players[presence.GetUserId()] = player
	s.logger.Info("Player joined: %s as %s", presence.GetUsername(), symbol)

	if len(state.Players) == 1 {
		state.CurrentTurnID = presence.GetUserId()
		// Don't set TurnStartTime yet - wait for game to start
	}

	if len(state.Players) == MaxPlayers {
		// Game is starting now, set the turn start time
		state.TurnStartTime = time.Now().Unix()
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
		} else {
			// Notify that player disconnected
			s.broadcastState(state, OpCodeState)
		}
	}
}

// ProcessRematch handles a rematch request
func (s *GameService) ProcessRematch(ctx context.Context, state *MatchState, userID string) error {
	_, err := s.handleRematchRequest(ctx, state, userID)
	return err
}

// HandleSignal processes custom signals from clients
func (s *GameService) HandleSignal(ctx context.Context, state *MatchState, userID string, data string) (string, error) {
	var signalData map[string]interface{}
	if err := utils.JsonUnmarshal([]byte(data), &signalData); err != nil {
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
	s.logger.Info("Handling rematch request for user %s", userID)
	if !state.GameOver {
		s.logger.Warn("Rematch rejected: Game not over")
		return "", fmt.Errorf("game is still in progress")
	}

	// Mark this player as wanting a rematch
	if state.RematchRequests == nil {
		state.RematchRequests = make(map[string]bool)
	}
	state.RematchRequests[userID] = true
	s.logger.Info("Player %s requested rematch. Total requests: %d", userID, len(state.RematchRequests))

	// Check if all connected players have requested
	connectedCount := 0
	requestsCount := 0
	for _, p := range state.Players {
		if p.IsConnected {
			connectedCount++
			if state.RematchRequests[p.UserID] {
				requestsCount++
			}
		}
	}

	s.logger.Info("Rematch status: %d/%d connected players requested", requestsCount, connectedCount)

	if requestsCount < connectedCount {
		// Not everyone has requested yet
		s.logger.Info("Waiting for other players to request rematch")
		s.broadcastState(state, OpCodeState)
		return "rematch_requested", nil
	}

	if connectedCount < 2 {
		s.logger.Info("Not enough players for rematch (only %d connected)", connectedCount)
		// Broadcast state so the client knows their request was registered
		s.broadcastState(state, OpCodeState)
		return "waiting_for_players", nil
	}

	s.logger.Info("All players requested rematch! Resetting game...")

	// Reset game state but keep players
	state.Board = [BoardSize]string{}
	state.GameOver = false
	state.Winner = ""
	state.IsDraw = false
	state.MoveCount = 0
	state.RematchRequests = make(map[string]bool)

	// Switch first turn to the other player
	for id := range state.Players {
		if id != state.CurrentTurnID {
			state.CurrentTurnID = id
			break
		}
	}

	s.logger.Info("Game reset. New start player: %s", state.CurrentTurnID)
	s.broadcastState(state, OpCodeState)
	return "rematch_accepted", nil
}

// handleChatMessage processes and persists chat messages
func (s *GameService) handleChatMessage(ctx context.Context, state *MatchState, userID string, data map[string]interface{}) (string, error) {
	message, ok := data["message"].(string)
	if !ok {
		return "", fmt.Errorf("missing message content")
	}

	// Validate message length
	if len(message) == 0 || len(message) > 500 {
		return "", fmt.Errorf("message must be between 1-500 characters")
	}

	player, ok := state.Players[userID]
	if !ok {
		return "", fmt.Errorf("player not found")
	}

	// Prepare chat data
	chatData := map[string]interface{}{
		"type":      "chat",
		"sender":    player.Username,
		"message":   message,
		"timestamp": time.Now().Unix(),
	}

	chatJSON, _ := json.Marshal(chatData)

	s.dispatcher.BroadcastMessage(OpCodeChat, chatJSON, nil, nil, true)

	s.persistChatMessage(ctx, userID, player.Username, message)

	return "message_sent", nil
}

func (s *GameService) persistChatMessage(ctx context.Context, userID, username, message string) {
	query := `
    INSERT INTO match_chat (user_id, username, message, created_at)
    VALUES ($1, $2, $3, NOW())
    `

	_, err := s.db.ExecContext(ctx, query, userID, username, message)
	if err != nil {
		s.logger.Error("Failed to persist chat message: %v", err)
	}
}

// / updatePlayerStats updates leaderboards and player records
func (s *GameService) updatePlayerStats(ctx context.Context, state *MatchState, userID string, won bool) {
	player, exists := state.Players[userID]
	if !exists {
		s.logger.Error("Player not found for stats update: %s", userID)
		return
	}

	s.logger.Info("Updating stats for player %s (%s), won: %v", userID, player.Username, won)

	if won {
		player.Wins++
		player.Streak++

		// Ensure leaderboards exist (create on demand if missing)
		if err := dbpkg.EnsureLeaderboards(s.logger, s.nk); err != nil {
			s.logger.Warn("Failed to ensure leaderboards before write: %v", err)
		}

		serverCtx := context.Background()

		// Increment wins leaderboard
		record, err := s.nk.LeaderboardRecordWrite(serverCtx, "global_wins", userID, player.Username, 1, 0, nil, nil)
		if err != nil {
			s.logger.Error("Failed to update wins leaderboard for %s: %v", userID, err)
		} else {
			s.logger.Info("Successfully updated wins leaderboard for %s: score=%d", userID, record.GetScore())
		}

		// Update win streak
		record, err = s.nk.LeaderboardRecordWrite(serverCtx, "win_streaks", userID, player.Username, int64(player.Streak), 0, nil, nil)
		if err != nil {
			s.logger.Error("Failed to update streak leaderboard for %s: %v", userID, err)
		} else {
			s.logger.Info("Successfully updated streak leaderboard for %s: score=%d", userID, record.GetScore())
		}
	} else if !state.IsDraw {
		player.Losses++
		player.Streak = 0 // Reset streak on loss
		s.logger.Info("Reset streak for player %s due to loss", userID)
	}
}

// recordMatchHistory persists match outcome to database
func (s *GameService) recordMatchHistory(ctx context.Context, state *MatchState) {
	if state.Winner == "" && !state.IsDraw {
		return // Skip if no valid outcome
	}

	query := `
    INSERT INTO match_history (match_id, winner_id, loser_id, mode, duration_seconds)
    VALUES ($1, $2, $3, $4, $5)
    ON CONFLICT (match_id) DO NOTHING
    `

	var loserID *string
	if state.Winner != "" {
		for id := range state.Players {
			if id != state.Winner {
				loserID = &id
				break
			}
		}
	}

	// Calculate duration in seconds
	duration := int((time.Now().Unix() - state.TurnStartTime) / 60)
	if duration < 0 {
		duration = 0
	}

	_, err := s.db.ExecContext(ctx, query, state.Winner, state.Winner, loserID, state.Mode, duration)
	if err != nil {
		s.logger.Error("Failed to record match history: %v", err)
	}
}

// broadcastState sends current game state to all connected players
func (s *GameService) broadcastState(state *MatchState, opCode int64) {
	stateJSON, err := utils.JsonMarshal(state)
	if err != nil {
		s.logger.Error("Failed to marshal game state: %v", err)
		return
	}

	s.dispatcher.BroadcastMessage(opCode, stateJSON, nil, nil, true)
}
