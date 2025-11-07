import 'package:equatable/equatable.dart';

class PlayerModel extends Equatable {
  final String id;
  final String username;
  final String symbol;
  final int wins;
  final int losses;
  final int draws;
  final bool isConnected;

  const PlayerModel({
    required this.id,
    required this.username,
    required this.symbol,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.isConnected = true,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['user_id'] ?? '',
      username: json['username'] ?? 'Unknown',
      symbol: json['symbol'] ?? '',
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      isConnected: json['is_connected'] ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    symbol,
    wins,
    losses,
    draws,
    isConnected,
  ];
}
