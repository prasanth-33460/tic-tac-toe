import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthenticateEvent extends AuthEvent {
  final String username;

  const AuthenticateEvent(this.username);

  @override
  List<Object> get props => [username];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
