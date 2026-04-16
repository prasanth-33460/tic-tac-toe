import 'package:equatable/equatable.dart';

class GameStateModel extends Equatable {
  final List<String> board;
  final String currentTurnId;
  final String? winnerId;
  final bool gameOver;
  final bool isDraw;
  final String? player1Id;
  final String? player2Id;
  final String? player1Username;
  final String? player2Username;
  final int moveCount;
  final Map<String, dynamic>? players;
  final String mode;
  final int turnStartTime;
  final int turnTimeoutSecs;

  const GameStateModel({
    required this.board,
    required this.currentTurnId,
    this.winnerId,
    this.gameOver = false,
    this.isDraw = false,
    this.player1Id,
    this.player2Id,
    this.player1Username,
    this.player2Username,
    this.moveCount = 0,
    this.players,
    this.mode = 'classic',
    this.turnStartTime = 0,
    this.turnTimeoutSecs = 0,
  });

  String? getSymbolForUser(String userId) {
    if (players == null) return null;

    for (var playerData in players!.values) {
      if (playerData is Map<String, dynamic>) {
        if (playerData['user_id'] == userId) {
          return playerData['symbol'] as String?;
        }
      }
    }
    return null;
  }

  /// Returns the username for the given user ID, or null if not found.
  String? getUsernameForUser(String userId) {
    if (players == null) return null;

    for (var playerData in players!.values) {
      if (playerData is Map<String, dynamic>) {
        if (playerData['user_id'] == userId) {
          return playerData['username'] as String?;
        }
      }
    }
    return null;
  }

  factory GameStateModel.empty() {
    return GameStateModel(
      board: List.filled(9, ''),
      currentTurnId: '',
      moveCount: 0,
    );
  }

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    String? player1Id;
    String? player2Id;
    String? player1Username;
    String? player2Username;

    // Normalize players into a list of maps regardless of server format.
    final rawPlayers = json['players'];
    final List<Map<String, dynamic>> playerEntries = [];
    Map<String, dynamic>? playersMap;

    if (rawPlayers is Map<String, dynamic>) {
      playersMap = rawPlayers;
      for (final v in rawPlayers.values) {
        if (v is Map<String, dynamic>) playerEntries.add(v);
      }
    } else if (rawPlayers is List<dynamic>) {
      // Convert list to a map keyed by user_id so the rest of the app
      // can look players up uniformly.
      playersMap = {};
      for (final v in rawPlayers) {
        if (v is Map<String, dynamic>) {
          playerEntries.add(v);
          final uid = v['user_id'] as String?;
          if (uid != null) playersMap[uid] = v;
        }
      }
    }

    for (final entry in playerEntries) {
      final symbol = entry['symbol'] as String?;
      final userId = entry['user_id'] as String?;
      final username = entry['username'] as String?;

      if (symbol == 'X') {
        player1Id = userId;
        player1Username = username;
      } else if (symbol == 'O') {
        player2Id = userId;
        player2Username = username;
      }
    }

    return GameStateModel(
      board: List<String>.from(json['board'] ?? List.filled(9, '')),
      currentTurnId: json['current_turn_id'] ?? '',
      winnerId: json['winner'],
      gameOver: json['game_over'] ?? false,
      isDraw: json['is_draw'] ?? false,
      player1Id: player1Id,
      player2Id: player2Id,
      player1Username: player1Username,
      player2Username: player2Username,
      moveCount: json['move_count'] ?? 0,
      players: playersMap,
      mode: json['mode'] ?? 'classic',
      turnStartTime: json['turn_start_time'] ?? 0,
      turnTimeoutSecs: json['turn_timeout_secs'] ?? 0,
    );
  }

  GameStateModel copyWith({
    List<String>? board,
    String? currentTurnId,
    String? winnerId,
    bool? gameOver,
    bool? isDraw,
    String? player1Id,
    String? player2Id,
    String? player1Username,
    String? player2Username,
    int? moveCount,
    Map<String, dynamic>? players,
    String? mode,
    int? turnStartTime,
    int? turnTimeoutSecs,
  }) {
    return GameStateModel(
      board: board ?? this.board,
      currentTurnId: currentTurnId ?? this.currentTurnId,
      winnerId: winnerId ?? this.winnerId,
      gameOver: gameOver ?? this.gameOver,
      isDraw: isDraw ?? this.isDraw,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      player1Username: player1Username ?? this.player1Username,
      player2Username: player2Username ?? this.player2Username,
      moveCount: moveCount ?? this.moveCount,
      players: players ?? this.players,
      mode: mode ?? this.mode,
      turnStartTime: turnStartTime ?? this.turnStartTime,
      turnTimeoutSecs: turnTimeoutSecs ?? this.turnTimeoutSecs,
    );
  }

  @override
  List<Object?> get props => [
    board,
    currentTurnId,
    winnerId,
    gameOver,
    isDraw,
    player1Id,
    player2Id,
    player1Username,
    player2Username,
    moveCount,
    players,
    mode,
    turnStartTime,
    turnTimeoutSecs,
  ];
}
