import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/leaderboard/leaderboard_bloc.dart';
import '../bloc/leaderboard/leaderboard_event.dart';
import '../bloc/leaderboard/leaderboard_state.dart';
import '../config/app_theme.dart';
import '../services/nakama_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _formatUsername(String username) {
    if (username.startsWith('device_')) {
      final parts = username.split('_');
      if (parts.length >= 3) return parts[1];
    }
    return username;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LeaderboardBloc(context.read<NakamaService>())
            ..add(const FetchLeaderboardEvent()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Leaderboard'),
          centerTitle: true,
        ),
        body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, state) {
            if (state is LeaderboardLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (state is LeaderboardError) {
              return Center(
                child: Text(state.message, style: const TextStyle(color: AppColors.textPrimary)),
              );
            }

            if (state is LeaderboardLoaded) {
              if (state.players.isEmpty) {
                return const Center(
                  child: Text(
                    'No players yet',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 18),
                  ),
                );
              }

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.players.length,
                      itemBuilder: (context, index) {
                        final player = state.players[index];
                        final rawScore = player['score'];
                        final score = rawScore is int
                            ? rawScore
                            : (rawScore is num ? rawScore.toInt() : 0);

                        return _LeaderboardCard(
                          rank: index + 1,
                          username: _formatUsername(player['username'] ?? 'Unknown'),
                          score: score,
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
      ),
      child: const Column(
        children: [
          Icon(Icons.leaderboard, size: 48, color: AppColors.textPrimary),
          SizedBox(height: 8),
          Text(
            'Top Players',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Compete and climb the ranks!',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final String username;
  final int score;

  const _LeaderboardCard({
    required this.rank,
    required this.username,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: rank <= 3 ? Border.all(color: rankColor, width: AppSizes.borderWidth) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Row(
              children: [
                if (rank <= 3) ...[
                  Icon(_getRankIcon(), color: rankColor, size: 24),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    username,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$score pts',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.grey[400]!;
      case 3: return Colors.brown[300]!;
      default: return AppColors.primary;
    }
  }

  IconData _getRankIcon() {
    switch (rank) {
      case 1: return Icons.emoji_events;
      case 2: return Icons.military_tech;
      case 3: return Icons.workspace_premium;
      default: return Icons.person;
    }
  }
}
