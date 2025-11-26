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
      // Trim and sanitize username
      final cleanUsername = event.username.trim();
      // Ensure device ID has no spaces or special characters
      final safeUsername = cleanUsername.replaceAll(
        RegExp(r'[^a-zA-Z0-9_]'),
        '_',
      );

      // Step 2: Generate device ID from username
      // Thought: "Use username as device ID for simplicity"
      // We use a fixed prefix + username to ensure uniqueness per user,
      // but we don't want to create a new account every time.
      // However, Nakama's authenticateDevice with create: true will try to create a user.
      // If we pass 'username', it tries to set that username. If it exists, it fails.
      // To allow login with existing username, we should NOT pass username if we are just logging in.
      // But we don't know if the user exists.

      // Strategy: Try to authenticate WITHOUT username first (login).
      // If that fails (account doesn't exist), try to authenticate WITH username (register).
      // But wait, device ID is the key.
      // If we use a random device ID every time (like with timestamp), we are creating a NEW account every time.
      // That's why we get duplicate username error - we are creating a NEW user (new ID) but trying to assign an EXISTING username.

      // Fix: Use a consistent device ID for the username.
      // If the user enters "prasanth", the device ID should be "device_prasanth".
      // This way, if "device_prasanth" exists, it logs in.
      // If it doesn't exist, it creates it with username "prasanth".

      final deviceId = 'device_$safeUsername';

      // Step 3: Authenticate with Nakama
      final success = await nakamaService.authenticateDevice(
        deviceId,
        displayName: cleanUsername,
      );

      if (success) {
        // Step 4: Connect WebSocket for real-time
        await nakamaService.connectSocket();

        // Step 5: Emit success state
        // Fix: Emit the actual Nakama User ID (UUID), not the device ID
        final userId = nakamaService.userId;
        if (userId != null) {
          emit(AuthSuccess(userId: userId, username: event.username));
        } else {
          emit(const AuthError('Failed to get user ID after authentication'));
        }
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
