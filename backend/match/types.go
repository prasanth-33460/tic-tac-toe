package match

import (
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
)

// Match represents the main match instance that implements runtime.Match interface
type Match struct {
	service *GameService
}

// MatchState represents the complete state of a tic-tac-toe match
type MatchState struct {
	Board           [BoardSize]string      `json:"board"`
	Players         map[string]*PlayerData `json:"players"`
	CurrentTurnID   string                 `json:"current_turn_id"`
	Winner          string                 `json:"winner"`
	GameOver        bool                   `json:"game_over"`
	IsDraw          bool                   `json:"is_draw"`
	Mode            string                 `json:"mode"`
	TurnStartTime   int64                  `json:"turn_start_time"`
	TurnTimeoutSecs int                    `json:"turn_timeout_secs"`
	MoveCount       int                    `json:"move_count"`
	Metadata        map[string]interface{} `json:"metadata"`
	Preferences     map[string]string      `json:"preferences"`
}

// PlayerData contains information about each player in the match
type PlayerData struct {
	UserID      string `json:"user_id"`
	Username    string `json:"username"`
	Symbol      string `json:"symbol"`
	IsConnected bool   `json:"is_connected"`
	Wins        int    `json:"wins"`
	Losses      int    `json:"losses"`
	Streak      int    `json:"streak"`
}

// MoveMessage represents a player's move attempt
type MoveMessage struct {
	Position int `json:"position"`
}

// GameService handles the game business logic and operations
type GameService struct {
	logger     runtime.Logger
	db         *sql.DB
	nk         runtime.NakamaModule
	dispatcher runtime.MatchDispatcher
}

// ValidationResult represents the result of a validation check
type ValidationResult struct {
	Valid   bool   `json:"valid"`
	Message string `json:"message,omitempty"`
}

// OpCode represents different types of operations in the game
type OpCode int64

// MatchResult represents the outcome of a completed match
type MatchResult struct {
	Winner    string        `json:"winner"`
	IsDraw    bool          `json:"is_draw"`
	GameState *MatchState   `json:"game_state"`
	Players   []*PlayerData `json:"players"`
}

// MatchParams represents initialization parameters for a match
type MatchParams struct {
	Mode       string                 `json:"mode"`
	Metadata   map[string]interface{} `json:"metadata"`
	SkillLevel int                    `json:"skill_level"`
}
