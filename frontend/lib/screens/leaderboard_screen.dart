import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/leaderboard/leaderboard_bloc.dart';
import '../bloc/leaderboard/leaderboard_event.dart';
import '../bloc/leaderboard/leaderboard_state.dart';
import '../services/nakama_service.dart';

/// Leaderboard Screen - Top players
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.players.length,
                itemBuilder: (context, index) {
                  final player = state.players[index];
                  return _LeaderboardCard(
                    rank: index + 1,
                    username: player['username'] ?? 'Unknown',
                    score: player['score'] ?? 0,
                  );
                },
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
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3 ? Border.all(color: _getRankColor(), width: 2) : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Username
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          // Score
          Text(
            '$score pts',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00D4FF),
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
}
