import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_state.dart';
import '../config/app_theme.dart';
import 'game_screen.dart';

class MatchmakingScreen extends StatelessWidget {
  final String mode;

  const MatchmakingScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isJoining = mode == 'join';

    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GamePlaying) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<GameBloc>(),
                child: const GameScreen(),
              ),
            ),
          );
        } else if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
          );
          final bloc = context.read<GameBloc>();
          Navigator.of(context).popUntil((route) => route.isFirst);
          Future.microtask(() => bloc.close());
        }
      },
      builder: (context, state) {
        String displayCode = '';
        if (state is GameMatchCreated) {
          displayCode = state.shortCode.isNotEmpty
              ? state.shortCode
              : state.matchId;
        }

        String modeDisplay;
        switch (mode) {
          case 'classic':
            modeDisplay = 'Classic';
            break;
          case 'timed':
            modeDisplay = 'Timed';
            break;
          default:
            modeDisplay = 'Joining';
        }

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {},
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeBadge(modeDisplay),
                    const SizedBox(height: 40),

                    Text(
                      isJoining ? 'Joining Match...' : 'Match Created!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      isJoining
                          ? 'Waiting for the game to start...'
                          : 'Share this Match ID with a friend to start playing:',
                      style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    if (displayCode.isNotEmpty) _buildCodeCard(context, displayCode),
                    const SizedBox(height: 40),

                    _buildLoadingSpinner(),
                    const SizedBox(height: 60),

                    TextButton(
                      onPressed: () {
                        final bloc = context.read<GameBloc>();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        Future.microtask(() => bloc.close());
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, color: AppColors.primary),
                      ),
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

  Widget _buildModeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: AppColors.primary, width: AppSizes.borderWidth),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCodeCard(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: AppColors.primary, width: AppSizes.borderWidth),
      ),
      child: Column(
        children: [
          const Text(
            'Match Code',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Match ID copied to clipboard!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, color: AppColors.primary),
                tooltip: 'Copy Match ID',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSpinner() {
    return const Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        Text(
          'O',
          style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ],
    );
  }
}
