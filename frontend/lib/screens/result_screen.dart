import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../config/app_theme.dart';

class ResultScreen extends StatelessWidget {
  final String? winnerId;
  final bool isDraw;
  final bool didIWin;

  const ResultScreen({
    super.key,
    this.winnerId,
    required this.isDraw,
    required this.didIWin,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor = _getResultColor();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isDraw ? '=' : (didIWin ? '✓' : 'X'),
                  style: TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  _getResultText(),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  _getPointsText(),
                  style: const TextStyle(fontSize: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 60),

                Container(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    border: Border.all(color: AppColors.primary, width: AppSizes.borderWidth),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'W/L/D',
                        value: didIWin ? '1/0/0' : (isDraw ? '0/0/1' : '0/1/0'),
                      ),
                      _StatItem(label: 'Streak', value: didIWin ? '1' : '0'),
                    ],
                  ),
                ),
                const SizedBox(height: 60),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _backToMenu(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                    child: const Text(
                      'Back to Menu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
    if (isDraw) return AppColors.textMuted;
    return didIWin ? AppColors.primary : AppColors.danger;
  }

  String _getResultText() {
    if (isDraw) return 'DRAW!';
    return didIWin ? 'WINNER!' : 'DEFEAT';
  }

  String _getPointsText() {
    if (isDraw) return '+50 pts';
    return didIWin ? '+200 pts' : '+0 pts';
  }

  void _backToMenu(BuildContext context) {
    final bloc = context.read<GameBloc>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    Future.microtask(() => bloc.close());
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
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
