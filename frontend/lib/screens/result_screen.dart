import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';

/// Result Screen - Game over, show winner
/// Thought: "Victory/defeat screen with stats and play again option"
class ResultScreen extends StatelessWidget {
  final String? winnerId;
  final bool isDraw;
  final bool didIWin;

  const ResultScreen({
    Key? key,
    this.winnerId,
    required this.isDraw,
    required this.didIWin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Result symbol (X or winner symbol)
                Text(
                  isDraw ? '=' : (didIWin ? '✓' : 'X'),
                  style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: _getResultColor(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Result text
                  Text(
                    _getResultText(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _getResultColor(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Points earned
                  Text(
                    _getPointsText(),
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 60),

                  // Stats container (matches sample)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F27),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00D4FF),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'W/L/D',
                          value: didIWin
                              ? '1/0/0'
                              : (isDraw ? '0/0/1' : '0/1/0'),
                        ),
                        _StatItem(label: 'Streak', value: didIWin ? '1' : '0'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Play Again button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _playAgain(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Back to Menu button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _backToMenu(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1F27),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back to Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Color _getResultColor() {
    if (isDraw) return Colors.grey;
    return didIWin ? const Color(0xFF00D4FF) : Colors.red;
  }

  String _getResultText() {
    if (isDraw) return 'DRAW!';
    return didIWin ? 'WINNER!' : 'DEFEAT';
  }

  String _getPointsText() {
    if (isDraw) return '+50 pts';
    return didIWin ? '+200 pts' : '+0 pts';
  }

  void _playAgain(BuildContext context) {
    // Request rematch
    context.read<GameBloc>().add(const RematchEvent());
    // Show snackbar or loading indicator?
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rematch requested. Waiting for opponent...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _backToMenu(BuildContext context) {
    context.read<GameBloc>().add(const LeaveMatchEvent());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
