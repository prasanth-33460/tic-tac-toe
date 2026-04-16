import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/nakama_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final NakamaService nakamaService;

  AuthBloc(this.nakamaService) : super(const AuthInitial()) {
    on<AuthenticateEvent>(_onAuthenticate);
    on<LogoutEvent>(_onLogout);
  }

  /// Converts a raw nickname into a Nakama-safe username.
  /// Nakama only allows [a-zA-Z0-9_] and the name must start with
  /// an alphanumeric character.
  static String sanitizeUsername(String raw) {
    final lower = raw.trim().toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    // Strip leading underscores so it starts with an alphanumeric char.
    final trimmed = cleaned.replaceAll(RegExp(r'^_+'), '');
    if (trimmed.isEmpty) return 'player_${DateTime.now().millisecondsSinceEpoch}';
    return trimmed;
  }

  Future<void> _onAuthenticate(
    AuthenticateEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final safeUsername = sanitizeUsername(event.username);
      final deviceId = 'device_$safeUsername';

      final success = await nakamaService.authenticateDevice(
        deviceId,
        displayName: safeUsername,
      );

      if (!success) {
        emit(const AuthError('Authentication failed. Please try again.'));
        return;
      }

      await nakamaService.connectSocket();

      final nakamaUserId = nakamaService.userId;
      if (nakamaUserId == null) {
        emit(const AuthError('Session invalid after authentication.'));
        return;
      }

      debugPrint('Auth success: userId=$nakamaUserId, name=$safeUsername');
      emit(AuthSuccess(userId: nakamaUserId, username: safeUsername));
    } catch (e) {
      emit(AuthError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await nakamaService.disconnect();
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }
}
