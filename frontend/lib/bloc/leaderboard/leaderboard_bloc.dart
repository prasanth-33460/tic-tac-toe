import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/nakama_service.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final NakamaService nakamaService;

  LeaderboardBloc(this.nakamaService) : super(const LeaderboardInitial()) {
    on<FetchLeaderboardEvent>(_onFetchLeaderboard);
    on<RefreshLeaderboardEvent>(_onRefreshLeaderboard);
  }

  Future<void> _onFetchLeaderboard(
    FetchLeaderboardEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());

    try {
      final data = await nakamaService.getLeaderboard();
      final players = List<Map<String, dynamic>>.from(
        data['global_wins'] ?? [],
      );

      emit(LeaderboardLoaded(players));
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }

  Future<void> _onRefreshLeaderboard(
    RefreshLeaderboardEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    add(const FetchLeaderboardEvent());
  }
}
