import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../bloc/game/game_state.dart';
import 'game_screen.dart';
import 'result_screen.dart';

/// Matchmaking Screen - Waiting for opponent
/// Acts as the main Game Container switching views based on state
class MatchmakingScreen extends StatelessWidget {
  final String mode;

  const MatchmakingScreen({Key? key, required this.mode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 MatchmakingScreen building for mode: $mode');
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        debugPrint('🎯 MatchmakingScreen state changed: ${state.runtimeType}');

        // Handle navigation back to menu
        if (state is GameInitial) {
          debugPrint(
            '🔙 GameInitial state detected - popping MatchmakingScreen',
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }

        if (state is GameError) {
          debugPrint('❌ Game error: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        // ✅ STATE BASED NAVIGATION (Container Pattern)
        if (state is GamePlaying) {
          return const GameScreen();
        } else if (state is GameOver) {
          final bloc = context.read<GameBloc>();
          return ResultScreen(
            winnerId: state.finalState.winnerId,
            isDraw: state.finalState.isDraw,
            didIWin: state.finalState.winnerId == bloc.userId,
          );
        }

        // Default: Matchmaking/Waiting UI
        return _buildMatchmakingUI(context, state);
      },
    );
  }

  Widget _buildMatchmakingUI(BuildContext context, GameState state) {
    String displayCode = '';
    bool isSearching = false;

    if (state is GameMatchCreated) {
      displayCode = state.shortCode.isNotEmpty
          ? state.shortCode
          : state.matchId;
    } else if (state is GameMatchmaking) {
      displayCode = state.shortCode.isNotEmpty
          ? state.shortCode
          : state.matchId;
    } else if (state is GameSearching) {
      isSearching = true;
    }

    final modeDisplay = mode == 'classic' ? 'Classic' : 'Timed';

    return WillPopScope(
      onWillPop: () async {
        debugPrint('⬅️ Back button pressed - leaving match');
        context.read<GameBloc>().add(const LeaveMatchEvent());
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1419),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mode display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F27),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00D4FF),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    modeDisplay,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00D4FF),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Status text
                Text(
                  isSearching ? 'Searching for opponent...' : 'Match Created!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00D4FF),
                  ),
                ),
                const SizedBox(height: 20),

                // Instructions
                if (!isSearching)
                  const Text(
                    'Share this Match ID with a friend to start playing:',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),

                // Match ID display - more prominent
                if (displayCode.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F27),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00D4FF),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Match Code',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                displayCode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF00D4FF),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: displayCode),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Match ID copied to clipboard!',
                                      ),
                                      backgroundColor: Color(0xFF00D4FF),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.copy,
                                color: Color(0xFF00D4FF),
                              ),
                              tooltip: 'Copy Match ID',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),

                // Animated loading indicator with "O"
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF00D4FF).withOpacity(0.3),
                        ),
                        strokeWidth: 4,
                      ),
                    ),
                    const Text(
                      'O',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
