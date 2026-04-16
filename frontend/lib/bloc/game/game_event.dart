import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class CreateMatchEvent extends GameEvent {
  const CreateMatchEvent(this.mode);

  final String mode;

  @override
  List<Object?> get props => [mode];
}

class JoinMatchEvent extends GameEvent {
  const JoinMatchEvent(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}

class MakeMoveEvent extends GameEvent {
  final int position;

  const MakeMoveEvent(this.position);

  @override
  List<Object> get props => [position];
}

class GameStateUpdateEvent extends GameEvent {
  final Map<String, dynamic> stateData;

  const GameStateUpdateEvent(this.stateData);

  @override
  List<Object> get props => [stateData];
}

class RematchEvent extends GameEvent {
  const RematchEvent();
}

class LeaveMatchEvent extends GameEvent {
  const LeaveMatchEvent();
}

class SendChatMessageEvent extends GameEvent {
  final String message;

  const SendChatMessageEvent(this.message);

  @override
  List<Object> get props => [message];
}
