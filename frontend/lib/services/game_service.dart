import '../config/app_config.dart';

class GameService {
  static const List<List<int>> winPatterns = [
    [0, 1, 2], // top row
    [3, 4, 5], // middle row
    [6, 7, 8], // bottom row
    [0, 3, 6], // left column
    [1, 4, 7], // middle column
    [2, 5, 8], // right column
    [0, 4, 8], // diagonal \
    [2, 4, 6], // diagonal /
  ];

  static bool isValidMove(List<String> board, int position) {
    if (position < 0 || position >= AppConfig.boardSize) return false;
    return board[position].isEmpty;
  }

  static String? checkWinner(List<String> board) {
    for (final pattern in winPatterns) {
      final a = board[pattern[0]];
      final b = board[pattern[1]];
      final c = board[pattern[2]];

      if (a.isNotEmpty && a == b && b == c) {
        return a;
      }
    }
    return null;
  }

  static bool isBoardFull(List<String> board) {
    return !board.contains('');
  }
}
