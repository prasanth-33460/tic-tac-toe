import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../bloc/game/game_state.dart';
import '../models/game_state_model.dart';
import '../widgets/game_board.dart';
import '../widgets/player_card.dart';
import 'result_screen.dart';

/// Game Screen - Active gameplay
/// Thought: "Main game screen with board and player info"
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(GameStateModel gameState) {
    _timer?.cancel();

    if (gameState.mode != 'timed' || gameState.turnTimeoutSecs == 0) {
      setState(() => _remainingSeconds = 0);
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = now - gameState.turnStartTime;
    final remaining = gameState.turnTimeoutSecs - elapsed;

    // Ensure timer never shows more than the timeout seconds
    final clampedRemaining = remaining.clamp(0, gameState.turnTimeoutSecs);
    setState(() => _remainingSeconds = clampedRemaining);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final elapsed = now - gameState.turnStartTime;
      final remaining = gameState.turnTimeoutSecs - elapsed;

      // Ensure timer never shows more than the timeout seconds
      final clampedRemaining = remaining.clamp(0, gameState.turnTimeoutSecs);

      if (clampedRemaining <= 0) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds = clampedRemaining);
      }
    });
  }

  String _getOpponentName(GamePlaying state) {
    final opponentSymbol = state.mySymbol == 'X' ? 'O' : 'X';
    if (state.gameState.players != null) {
      for (var p in state.gameState.players!.values) {
        if (p is Map && p['symbol'] == opponentSymbol) {
          return p['username'] as String? ?? 'Opponent';
        }
      }
    }
    return 'Opponent';
  }

  String _getMyName(GamePlaying state) {
    if (state.gameState.players != null) {
      for (var p in state.gameState.players!.values) {
        if (p is Map && p['symbol'] == state.mySymbol) {
          return p['username'] as String? ?? 'You';
        }
      }
    }
    return 'You';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        // Navigate to result screen when game ends
        if (state is GameOver) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<GameBloc>(),
                child: ResultScreen(
                  winnerId: state.winnerId,
                  isDraw: state.isDraw,
                  didIWin: state.didIWin,
                ),
              ),
            ),
          );
        }

        // Start timer for timed mode when game state changes
        if (state is GamePlaying && state.gameState.mode == 'timed') {
          _startTimer(state.gameState);
        }
      },
      builder: (context, state) {
        if (state is! GamePlaying) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F1419),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
              ),
            ),
          );
        }

        return WillPopScope(
          onWillPop: () async {
            // Confirm before leaving
            final shouldLeave = await _showLeaveDialog(context);
            if (shouldLeave == true) {
              context.read<GameBloc>().add(const LeaveMatchEvent());
            }
            return shouldLeave ?? false;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0F1419),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top player card (opponent)
                    PlayerCard(
                      symbol: state.mySymbol == 'X' ? 'O' : 'X',
                      isActive: !state.isMyTurn,
                      username: _getOpponentName(state),
                    ),

                    // Timer display for timed mode
                    if (state.gameState.mode == 'timed')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F26),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _remainingSeconds <= 5
                                  ? Colors.red
                                  : const Color(0xFF00D4FF),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                color: _remainingSeconds <= 5
                                    ? Colors.red
                                    : const Color(0xFF00D4FF),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                state.isMyTurn
                                    ? 'Your turn: $_remainingSeconds seconds'
                                    : 'Opponent\'s turn: $_remainingSeconds seconds',
                                style: TextStyle(
                                  color: _remainingSeconds <= 5
                                      ? Colors.red
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Builder(
                      builder: (context) {
                        return const SizedBox.shrink();
                      },
                    ),

                    const Spacer(),

                    // Game board
                    GameBoard(
                      board: state.gameState.board,
                      onCellTap: (index) {
                        if (state.isMyTurn) {
                          context.read<GameBloc>().add(MakeMoveEvent(index));
                        }
                      },
                      enabled: state.isMyTurn,
                    ),

                    const Spacer(),

                    // Bottom player card (me)
                    PlayerCard(
                      symbol: state.mySymbol,
                      isActive: state.isMyTurn,
                      username: _getMyName(state),
                      isMe: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showLeaveDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F27),
        title: const Text(
          'Leave Match?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You will lose this match if you leave.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
