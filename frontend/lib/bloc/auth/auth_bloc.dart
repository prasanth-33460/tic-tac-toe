import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/nakama_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC - handles authentication logic
/// Thought: "Receives events -> processes -> emits states"
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final NakamaService nakamaService;

  AuthBloc(this.nakamaService) : super(const AuthInitial()) {
    // Register event handlers
    on<AuthenticateEvent>(_onAuthenticate);
    on<LogoutEvent>(_onLogout);
  }

  /// Handle authentication event
  /// Thought: "User clicked login -> authenticate with Nakama"
  Future<void> _onAuthenticate(
    AuthenticateEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Step 1: Show loading
    emit(const AuthLoading());

    try {
      // Step 2: Generate device ID from username
      // Thought: "Use username as device ID for simplicity"
      final deviceId =
          'device_${event.username}_${DateTime.now().millisecondsSinceEpoch}';

      // Step 3: Authenticate with Nakama
      final success = await nakamaService.authenticateDevice(
        deviceId,
        displayName: event.username,
      );

      if (success) {
        // Step 4: Connect WebSocket for real-time
        await nakamaService.connectSocket();

        // Step 5: Emit success state
        emit(AuthSuccess(userId: deviceId, username: event.username));
      } else {
        // Authentication failed
        emit(const AuthError('Authentication failed. Please try again.'));
      }
    } catch (e) {
      // Catch any errors
      emit(AuthError('Error: ${e.toString()}'));
    }
  }

  /// Handle logout event
  /// Thought: "User wants to logout -> disconnect and reset"
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await nakamaService.disconnect();
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }
}
