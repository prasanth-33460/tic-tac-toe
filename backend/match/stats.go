package match

import (
	"context"

	dbpkg "github.com/prasanth-33460/tic-tac-toe/backend/db"
)

// updatePlayerStats updates the in-memory player record and writes to the Nakama leaderboards.
func (s *GameService) updatePlayerStats(ctx context.Context, state *MatchState, userID string, won bool) {
	player, exists := state.Players[userID]
	if !exists {
		return
	}

	if won {
		player.Wins++
		player.Streak++
		s.writeLeaderboardRecords(ctx, userID, player)
	} else if state.IsDraw {
		player.Draws++
	} else {
		player.Losses++
		player.Streak = 0
	}
}

func (s *GameService) writeLeaderboardRecords(ctx context.Context, userID string, player *PlayerData) {
	if err := dbpkg.EnsureLeaderboards(s.logger, s.nk); err != nil {
		s.logger.Warn("Leaderboard ensure failed: %v", err)
	}

	serverCtx := context.Background()

	if _, err := s.nk.LeaderboardRecordWrite(serverCtx, LeaderboardGlobalWins, userID, player.Username, 1, 0, nil, nil); err != nil {
		s.logger.Error("Wins leaderboard write failed for %s: %v", userID, err)
	}

	if _, err := s.nk.LeaderboardRecordWrite(serverCtx, LeaderboardWinStreaks, userID, player.Username, int64(player.Streak), 0, nil, nil); err != nil {
		s.logger.Error("Streak leaderboard write failed for %s: %v", userID, err)
	}
}

// recordMatchHistory persists the match outcome to the database.
func (s *GameService) recordMatchHistory(ctx context.Context, state *MatchState) {
	if state.Winner == "" && !state.IsDraw {
		return
	}

	var loserID *string
	if state.Winner != "" {
		for id := range state.Players {
			if id != state.Winner {
				loserCopy := id
				loserID = &loserCopy
				break
			}
		}
	}

	matchID := state.MatchID
	if matchID == "" {
		matchID = dbpkg.GenerateFallbackMatchID(state.Winner)
		s.logger.Warn("MatchID missing, using generated key: %s", matchID)
	}

	repo := dbpkg.NewRepository(s.db)
	if err := repo.RecordMatchResult(ctx, matchID, state.Winner, loserID, state.Mode, state.StartTime); err != nil {
		s.logger.Error("Failed to record match history: %v", err)
	}
}
