package rpc

// MatchRequest represents a matchmaking request
type MatchRequest struct {
	Mode        string            `json:"mode"`
	SkillLevel  int               `json:"skill_level"`  // Player's skill rating (1-100)
	Preferences map[string]string `json:"preferences"`  // Player's game preferences
	RatingRange int               `json:"rating_range"` // Acceptable rating difference
	Metadata    map[string]string `json:"metadata"`     // Additional match metadata
}

// LeaderboardEntry represents a single leaderboard entry
type LeaderboardEntry struct {
	UserID   string `json:"user_id"`
	Username string `json:"username"`
	Score    int64  `json:"score"`
	Rank     int64  `json:"rank"`
}

// LeaderboardResponse contains the full leaderboard data
type LeaderboardResponse struct {
	GlobalWins []LeaderboardEntry `json:"global_wins"`
	WinStreaks []LeaderboardEntry `json:"win_streaks"`
}
