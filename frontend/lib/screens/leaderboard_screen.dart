import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/leaderboard/leaderboard_bloc.dart';
import '../bloc/leaderboard/leaderboard_event.dart';
import '../bloc/leaderboard/leaderboard_state.dart';
import '../services/nakama_service.dart';

/// Leaderboard Screen - Top players
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _formatUsername(String username) {
    // If it starts with "device_", extract a cleaner name
    if (username.startsWith('device_')) {
      // Extract the part after "device_" and before the timestamp
      final parts = username.split('_');
      if (parts.length >= 3) {
        // Return the name part (e.g., "prasanth" from "device_prasanth_176...")
        return parts[1];
      }
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
        backgroundColor: const Color(0xFF0F1419),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1F27),
          title: const Text('Leaderboard'),
          centerTitle: true,
        ),
        body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, state) {
            if (state is LeaderboardLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                ),
              );
            }

            if (state is LeaderboardError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (state is LeaderboardLoaded) {
              if (state.players.isEmpty) {
                return const Center(
                  child: Text(
                    'No players yet',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                );
              }

              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF1A1F27)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.leaderboard, size: 48, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          '🏆 Top Players',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Compete and climb the ranks!',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Leaderboard List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.players.length,
                      itemBuilder: (context, index) {
                        final player = state.players[index];
                        return _LeaderboardCard(
                          rank: index + 1,
                          username: _formatUsername(
                            player['username'] ?? 'Unknown',
                          ),
                          score: player['score'] ?? 0,
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F27),
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3 ? Border.all(color: _getRankColor(), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getRankColor(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getRankColor().withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Username with Trophy Icon for Top 3
          Expanded(
            child: Row(
              children: [
                if (rank <= 3) ...[
                  Icon(_getRankIcon(), color: _getRankColor(), size: 24),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    username,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Score with better formatting
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D4FF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${score.toString()} pts',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D4FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return const Color(0xFF00D4FF);
    }
  }

  IconData _getRankIcon() {
    switch (rank) {
      case 1:
        return Icons.emoji_events; // Trophy
      case 2:
        return Icons.military_tech; // Medal
      case 3:
        return Icons.workspace_premium; // Premium badge
      default:
        return Icons.person;
    }
  }
}
