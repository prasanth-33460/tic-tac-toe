import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class GameBoard extends StatelessWidget {
  final List<String> board;
  final Function(int) onCellTap;
  final bool enabled;

  const GameBoard({
    super.key,
    required this.board,
    required this.onCellTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            return _GameCell(
              value: board[index],
              onTap: enabled && board[index].isEmpty
                  ? () => onCellTap(index)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _GameCell extends StatelessWidget {
  final String value;
  final VoidCallback? onTap;

  const _GameCell({required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: value.isEmpty ? AppColors.background : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: _getCellColor(), width: AppSizes.borderWidth),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _getCellColor(),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCellColor() {
    if (value == 'X') return AppColors.primary;
    if (value == 'O') return AppColors.danger;
    return AppColors.cellEmpty;
  }
}
