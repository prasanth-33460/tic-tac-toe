import 'package:equatable/equatable.dart';

class MatchModel extends Equatable {
  final String matchId;
  final String shortCode;
  final String mode;
  final DateTime createdAt;

  const MatchModel({
    required this.matchId,
    required this.shortCode,
    required this.mode,
    required this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      matchId: json['matchId'] ?? '',
      shortCode: json['shortCode'] ?? '',
      mode: json['mode'] ?? 'classic',
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [matchId, shortCode, mode, createdAt];
}
