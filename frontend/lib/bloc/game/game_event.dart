import 'package:equatable/equatable.dart';

/// Events that can happen in a game
/// Thought: "What can happen? Create match, find match, make move, receive update"
abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// User wants to create a new match
/// Thought: "User clicked 'Create Match' button"
class CreateMatchEvent extends GameEvent {
  const CreateMatchEvent(this.mode);

  final String mode;

  @override
  List<Object?> get props => [mode];
}

/// User wants to join a match by ID
/// Thought: "User entered a match ID to join"
class JoinMatchEvent extends GameEvent {
  const JoinMatchEvent(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}

/// User joined a match
/// Thought: "Successfully joined a match, now waiting for opponent"
class MatchJoinedEvent extends GameEvent {
  final String matchId;

  const MatchJoinedEvent(this.matchId);

  @override
  List<Object> get props => [matchId];
}

/// User made a move
/// Thought: "User tapped a cell on the board"
class MakeMoveEvent extends GameEvent {
  final int position;

  const MakeMoveEvent(this.position);

  @override
  List<Object> get props => [position];
}

/// Received game state update from server
/// Thought: "Server sent updated game state"
class GameStateUpdateEvent extends GameEvent {
  final Map<String, dynamic> stateData;

  const GameStateUpdateEvent(this.stateData);

  @override
  List<Object> get props => [stateData];
}

/// Game ended
/// Thought: "Game is over, show results"
class GameEndedEvent extends GameEvent {
  final String? winnerId;
  final bool isDraw;

  const GameEndedEvent({this.winnerId, required this.isDraw});

  @override
  List<Object?> get props => [winnerId, isDraw];
}

/// User wants to play again
/// Thought: "User clicked 'Rematch' or 'Play Again'"
class RematchEvent extends GameEvent {
  const RematchEvent();
}

/// Leave current match
/// Thought: "User clicked back/quit"
class LeaveMatchEvent extends GameEvent {
  const LeaveMatchEvent();
}

/// User wants to find a match (auto matchmaking)
class FindMatchEvent extends GameEvent {
  const FindMatchEvent(this.mode);

  final String mode;

  @override
  List<Object?> get props => [mode];
}

/// Matchmaker found a match
class MatchFoundEvent extends GameEvent {
  final String matchId;

  const MatchFoundEvent(this.matchId);

  @override
  List<Object> get props => [matchId];
}
