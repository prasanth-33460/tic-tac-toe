import 'package:equatable/equatable.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object> get props => [];
}

/// Fetch leaderboard
class FetchLeaderboardEvent extends LeaderboardEvent {
  const FetchLeaderboardEvent();
}

/// Refresh leaderboard
class RefreshLeaderboardEvent extends LeaderboardEvent {
  const RefreshLeaderboardEvent();
}
