package rpc

// MatchRequest is the payload for match creation RPCs.
type MatchRequest struct {
	Mode        string            `json:"mode"`
	SkillLevel  int               `json:"skill_level"`
	Preferences map[string]string `json:"preferences"`
	RatingRange int               `json:"rating_range"`
	Metadata    map[string]string `json:"metadata"`
}

// LeaderboardEntry is a single row in a leaderboard.
type LeaderboardEntry struct {
	UserID   string `json:"user_id"`
	Username string `json:"username"`
	Score    int64  `json:"score"`
	Rank     int64  `json:"rank"`
}

// LeaderboardResponse wraps both leaderboard tables.
type LeaderboardResponse struct {
	GlobalWins []LeaderboardEntry `json:"global_wins"`
	WinStreaks []LeaderboardEntry `json:"win_streaks"`
}

// BanRequest is the payload for ban/unban RPCs.
type BanRequest struct {
	TargetUserID string `json:"target_user_id"`
	Reason       string `json:"reason"`
}

// BanResponse acknowledges a ban/unban operation.
type BanResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

// RematchRequest is the payload for rematch RPCs.
type RematchRequest struct {
	MatchID string `json:"match_id"`
}

// RematchResponse acknowledges a rematch request.
type RematchResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}
