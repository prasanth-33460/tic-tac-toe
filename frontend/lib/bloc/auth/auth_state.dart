import 'package:equatable/equatable.dart';

/// All possible authentication states
/// Thought: "Auth can be: Initial, Loading, Success, or Error"
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - not authenticated yet
/// Thought: "App just opened, user hasn't logged in"
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - authentication in progress
/// Thought: "Show spinner while connecting to server"
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Success state - user is authenticated
/// Thought: "Login successful, store user info"
class AuthSuccess extends AuthState {
  final String userId;
  final String username;

  const AuthSuccess({required this.userId, required this.username});

  @override
  List<Object> get props => [userId, username];
}

/// Error state - authentication failed
/// Thought: "Something went wrong, show error message"
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
