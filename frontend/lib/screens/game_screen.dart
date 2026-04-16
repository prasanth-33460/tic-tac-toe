import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../bloc/game/game_state.dart';
import '../config/app_theme.dart';
import '../models/game_state_model.dart';
import '../services/nakama_service.dart';
import '../widgets/chat_panel.dart';
import '../widgets/game_board.dart';
import '../widgets/player_card.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

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
    final clamped = (gameState.turnTimeoutSecs - elapsed)
        .clamp(0, gameState.turnTimeoutSecs);
    setState(() => _remainingSeconds = clamped);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final elapsed = now - gameState.turnStartTime;
      final clamped = (gameState.turnTimeoutSecs - elapsed)
          .clamp(0, gameState.turnTimeoutSecs);

      if (clamped <= 0) {
        timer.cancel();
      }
      setState(() => _remainingSeconds = clamped);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
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

        if (state is GamePlaying && state.gameState.mode == 'timed') {
          _startTimer(state.gameState);
        }
      },
      builder: (context, state) {
        if (state is! GamePlaying) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        }

        final gameBloc = context.read<GameBloc>();
        final myUserId = gameBloc.userId;
        final gs = state.gameState;

        final myUsername = gs.getUsernameForUser(myUserId) ?? 'You';
        final opponentSymbol = state.mySymbol == 'X' ? 'O' : 'X';

        String opponentUsername = 'Opponent';
        if (gs.players != null) {
          for (final entry in gs.players!.values) {
            if (entry is Map<String, dynamic> && entry['user_id'] != myUserId) {
              opponentUsername = entry['username'] ?? 'Opponent';
              break;
            }
          }
        }

        final nakamaService = context.read<NakamaService>();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final shouldLeave = await _showLeaveDialog(context);
            if (shouldLeave == true && context.mounted) {
              final bloc = context.read<GameBloc>();
              Navigator.of(context).popUntil((route) => route.isFirst);
              Future.microtask(() => bloc.close());
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.cardPadding),
                child: Column(
                  children: [
                    PlayerCard(
                      symbol: opponentSymbol,
                      isActive: !state.isMyTurn,
                      username: opponentUsername,
                    ),

                    if (state.gameState.mode == 'timed')
                      _buildTimerBar(state.isMyTurn),

                    const Spacer(),

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

                    PlayerCard(
                      symbol: state.mySymbol,
                      isActive: state.isMyTurn,
                      username: myUsername,
                      isMe: true,
                    ),

                    const SizedBox(height: 12),

                    _ChatButton(
                      nakamaService: nakamaService,
                      myUsername: myUsername,
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

  Widget _buildTimerBar(bool isMyTurn) {
    final isUrgent = _remainingSeconds <= 5;
    final color = isUrgent ? AppColors.danger : AppColors.primary;
    final textColor = isUrgent ? AppColors.danger : AppColors.textPrimary;
    final label = isMyTurn
        ? 'Your turn: $_remainingSeconds seconds'
        : 'Opponent\'s turn: $_remainingSeconds seconds';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: color, width: AppSizes.borderWidth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showLeaveDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Match?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'You will lose this match if you leave.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final NakamaService nakamaService;
  final String myUsername;

  const _ChatButton({
    required this.nakamaService,
    required this.myUsername,
  });

  void _openChat(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => ChatPanel(
          nakamaService: nakamaService,
          myUsername: myUsername,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openChat(context),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('Chat'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.surfaceAlt),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
        ),
      ),
    );
  }
}
