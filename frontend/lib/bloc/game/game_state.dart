import 'package:equatable/equatable.dart';
import '../../models/game_state_model.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameLoading extends GameState {
  final String message;

  const GameLoading({this.message = 'Loading...'});

  @override
  List<Object> get props => [message];
}

class GameMatchCreated extends GameState {
  final String matchId;
  final String shortCode;

  const GameMatchCreated({required this.matchId, required this.shortCode});

  @override
  List<Object> get props => [matchId, shortCode];
}

class GamePlaying extends GameState {
  final String matchId;
  final GameStateModel gameState;
  final bool isMyTurn;
  final String mySymbol;

  const GamePlaying({
    required this.matchId,
    required this.gameState,
    required this.isMyTurn,
    required this.mySymbol,
  });

  @override
  List<Object> get props => [matchId, gameState, isMyTurn, mySymbol];
}

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

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object> get props => [message];
}
