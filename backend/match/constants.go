package match

const (
	TickRate   = 1
	MaxPlayers = 2
	BoardSize  = 9

	ModeClassic = "classic"
	ModeTimed   = "timed"

	TurnTimeoutSecs = 30

	OpCodeMove    int64 = 1
	OpCodeState   int64 = 2
	OpCodeGameEnd int64 = 3
	OpCodeTimeout int64 = 4
	OpCodeChat    int64 = 5
)

var WinPatterns = [][]int{
	{0, 1, 2},
	{3, 4, 5},
	{6, 7, 8},
	{0, 3, 6},
	{1, 4, 7},
	{2, 5, 8},
	{0, 4, 8},
	{2, 4, 6},
}
