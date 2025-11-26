import 'package:equatable/equatable.dart';
import '../../models/game_state_model.dart';

/// All possible game states
/// Thought: "Game flow: Idle -> Matchmaking -> Playing -> GameOver"
abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no game yet
/// Thought: "User is at menu, no active game"
class GameInitial extends GameState {
  const GameInitial();
}

/// Loading state - creating or finding match
/// Thought: "Show spinner while backend creates match"
class GameLoading extends GameState {
  final String message;

  const GameLoading({this.message = 'Loading...'});

  @override
  List<Object> get props => [message];
}

/// Match created state - match created, waiting for opponent to join
/// Thought: "Match created with ID, show ID for sharing"
class GameMatchCreated extends GameState {
  final String matchId;
  final String shortCode;

  const GameMatchCreated({required this.matchId, required this.shortCode});

  @override
  List<Object> get props => [matchId, shortCode];
}

/// Matchmaking state - waiting for opponent
/// Thought: "Match created, waiting for second player"
class GameMatchmaking extends GameState {
  final String matchId;
  final String shortCode;
  final int secondsElapsed;

  const GameMatchmaking({
    required this.matchId,
    required this.shortCode,
    this.secondsElapsed = 0,
  });

  @override
  List<Object> get props => [matchId, shortCode, secondsElapsed];
}

/// Playing state - game is active
/// Thought: "Both players joined, game in progress"
class GamePlaying extends GameState {
  final String matchId;
  final GameStateModel gameState;
  final bool isMyTurn;
  final String mySymbol; // "X" or "O"

  const GamePlaying({
    required this.matchId,
    required this.gameState,
    required this.isMyTurn,
    required this.mySymbol,
  });

  @override
  List<Object> get props => [matchId, gameState, isMyTurn, mySymbol];
}

/// Game over state - game finished
/// Thought: "Show winner, stats, play again option"
class GameOver extends GameState {
  final String matchId;
  final GameStateModel finalState;
  final String? winnerId;
  final bool isDraw;
  final bool didIWin;

  const GameOver({
    required this.matchId,
    required this.finalState,
    this.winnerId,
    required this.isDraw,
    required this.didIWin,
  });

  @override
  List<Object?> get props => [matchId, finalState, winnerId, isDraw, didIWin];
}

/// Error state - something went wrong
/// Thought: "Network error, timeout, etc."
class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object> get props => [message];
}

/// Searching state - waiting for matchmaker
class GameSearching extends GameState {
  final String mode;

  const GameSearching({required this.mode});

  @override
  List<Object> get props => [mode];
}
