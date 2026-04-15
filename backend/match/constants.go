package match

const (
	TickRate   = 1
	MaxPlayers = 2
	BoardSize  = 9

	ModeClassic = "classic"
	ModeTimed   = "timed"

	// TurnTimeoutSecs is the per-turn time limit in timed mode.
	TurnTimeoutSecs = 15

	// SymbolX and SymbolO are the two player markers.
	SymbolX = "X"
	SymbolO = "O"

	// MaxSkillDiff is the maximum skill rating gap allowed when matching.
	MaxSkillDiff = 20

	// MaxChatLength is the maximum allowed characters in a chat message.
	MaxChatLength = 500

	// Leaderboard IDs used across the server.
	LeaderboardGlobalWins = "global_wins"
	LeaderboardWinStreaks = "win_streaks"

	// Op-codes for real-time match messages.
	OpCodeMove    int64 = 1
	OpCodeState   int64 = 2
	OpCodeGameEnd int64 = 3
	OpCodeTimeout int64 = 4
	OpCodeChat    int64 = 5
)

// WinPatterns lists every set of three board indices that form a line.
var WinPatterns = [][]int{
	{0, 1, 2}, // row 1
	{3, 4, 5}, // row 2
	{6, 7, 8}, // row 3
	{0, 3, 6}, // col 1
	{1, 4, 7}, // col 2
	{2, 5, 8}, // col 3
	{0, 4, 8}, // diagonal \
	{2, 4, 6}, // diagonal /
}
