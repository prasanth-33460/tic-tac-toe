import 'package:equatable/equatable.dart';

/// Events that can happen in authentication
/// Thought: "What can a user DO with auth? Login or Logout."
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// User wants to authenticate
/// Thought: "User enters username and taps login"
class AuthenticateEvent extends AuthEvent {
  final String username;

  const AuthenticateEvent(this.username);

  @override
  List<Object> get props => [username];
}

/// User wants to logout
/// Thought: "User leaves the game"
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
