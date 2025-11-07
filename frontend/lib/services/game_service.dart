import '../config/app_config.dart';

/// Local game logic service
/// Thought: "Some logic can run client-side for instant feedback"
class GameService {
  /// Win patterns for tic-tac-toe
  /// Thought: "8 ways to win - 3 rows, 3 columns, 2 diagonals"
  static const List<List<int>> winPatterns = [
    [0, 1, 2], // Top row
    [3, 4, 5], // Middle row
    [6, 7, 8], // Bottom row
    [0, 3, 6], // Left column
    [1, 4, 7], // Middle column
    [2, 5, 8], // Right column
    [0, 4, 8], // Diagonal top-left to bottom-right
    [2, 4, 6], // Diagonal top-right to bottom-left
  ];

  /// Check if move is valid locally
  /// Thought: "Before sending to server, check if cell is empty"
  static bool isValidMove(List<String> board, int position) {
    if (position < 0 || position >= AppConfig.boardSize) return false;
    return board[position].isEmpty;
  }

  /// Check for winner locally (for instant UI feedback)
  /// Thought: "Don't wait for server - show winner immediately"
  static String? checkWinner(List<String> board) {
    for (final pattern in winPatterns) {
      final a = board[pattern[0]];
      final b = board[pattern[1]];
      final c = board[pattern[2]];

      if (a.isNotEmpty && a == b && b == c) {
        return a; // Return "X" or "O"
      }
    }
    return null;
  }

  /// Check if board is full (draw)
  /// Thought: "All cells filled + no winner = draw"
  static bool isBoardFull(List<String> board) {
    return !board.contains('');
  }
}
