package match

import (
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
)

// Match implements the runtime.Match interface for tic-tac-toe.
type Match struct {
	service *GameService
}

// MatchState holds the full state of a single tic-tac-toe game.
type MatchState struct {
	MatchID         string                 `json:"match_id"`
	Board           [BoardSize]string      `json:"board"`
	Players         map[string]*PlayerData `json:"players"`
	CurrentTurnID   string                 `json:"current_turn_id"`
	Winner          string                 `json:"winner"`
	GameOver        bool                   `json:"game_over"`
	IsDraw          bool                   `json:"is_draw"`
	Mode            string                 `json:"mode"`
	StartTime       int64                  `json:"start_time"`
	TurnStartTime   int64                  `json:"turn_start_time"`
	TurnTimeoutSecs int                    `json:"turn_timeout_secs"`
	MoveCount       int                    `json:"move_count"`
	Metadata        map[string]interface{} `json:"metadata"`
	Preferences     map[string]string      `json:"preferences"`
}

// PlayerData tracks per-player info within a match.
type PlayerData struct {
	UserID      string `json:"user_id"`
	Username    string `json:"username"`
	Symbol      string `json:"symbol"`
	IsConnected bool   `json:"is_connected"`
	Wins        int    `json:"wins"`
	Losses      int    `json:"losses"`
	Draws       int    `json:"draws"`
	Streak      int    `json:"streak"`
}

// MoveMessage is the payload sent by a client when making a move.
type MoveMessage struct {
	Position int `json:"position"`
}

// GameService contains shared dependencies used by match logic.
type GameService struct {
	logger     runtime.Logger
	db         *sql.DB
	nk         runtime.NakamaModule
	dispatcher runtime.MatchDispatcher
}

// ValidationResult is the outcome of a pre-join or pre-move check.
type ValidationResult struct {
	Valid   bool   `json:"valid"`
	Message string `json:"message,omitempty"`
}


