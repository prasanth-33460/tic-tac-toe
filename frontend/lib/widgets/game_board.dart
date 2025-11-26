import 'package:flutter/material.dart';

/// Game Board Widget - 3x3 grid
/// Thought: "The heart of the game - the board itself"
class GameBoard extends StatelessWidget {
  final List<String> board;
  final Function(int) onCellTap;
  final bool enabled;

  const GameBoard({
    Key? key,
    required this.board,
    required this.onCellTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0, // Square board
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F27),
          borderRadius: BorderRadius.circular(16),
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
              onTap: () {
                if (enabled && board[index].isEmpty) {
                  onCellTap(index);
                } else {
                  debugPrint('🚫 Cell tap ignored. Enabled: $enabled, IsEmpty: ${board[index].isEmpty}');
                }
              },
            );
          },
        ),
      ),
    );
  }
}

/// Individual cell in the game board
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
          color: value.isEmpty
              ? const Color(0xFF0F1419)
              : const Color(0xFF1A1F27),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getCellColor(), width: 2),
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
    if (value == 'X') {
      return const Color(0xFF00D4FF); // Cyan for X
    } else if (value == 'O') {
      return Colors.red; // Red for O
    }
    return const Color(0xFF2A3038); // Grey for empty
  }
}
