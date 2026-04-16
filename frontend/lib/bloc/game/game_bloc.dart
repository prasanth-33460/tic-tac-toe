import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/game_state_model.dart';
import '../../services/nakama_service.dart';
import '../../services/game_service.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final NakamaService nakamaService;
  final String userId;
  final String mode;

  String? _currentMatchId;
  String? _mySymbol;
  bool _movePending = false;
  StreamSubscription<Map<String, dynamic>>? _matchStateSubscription;

  GameBloc({
    required this.nakamaService,
    required this.userId,
    required this.mode,
  }) : super(const GameInitial()) {
    on<CreateMatchEvent>(_onCreateMatch);
    on<JoinMatchEvent>(_onJoinMatch);
    on<MakeMoveEvent>(_onMakeMove);
    on<GameStateUpdateEvent>(_onGameStateUpdate);
    on<RematchEvent>(_onRematch);
    on<LeaveMatchEvent>(_onLeaveMatch);
    on<SendChatMessageEvent>(_onSendChatMessage);

    _subscribeToMatchUpdates();
  }

  void _subscribeToMatchUpdates() {
    _matchStateSubscription = nakamaService.matchStateStream.listen((data) {
      if (!isClosed) {
        add(GameStateUpdateEvent(data));
      }
    });
  }

  Future<void> _onCreateMatch(
    CreateMatchEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading(message: 'Creating match...'));

    try {
      final match = await nakamaService.findMatch(mode: event.mode);

      if (match == null) {
        emit(const GameError('Failed to create match'));
        return;
      }

      _currentMatchId = match.matchId;
      await nakamaService.joinMatch(match.matchId);

      emit(
        GameMatchCreated(matchId: match.matchId, shortCode: match.shortCode),
      );
      debugPrint('Match created: ${match.matchId}');
    } catch (e) {
      debugPrint('Error creating match: $e');
      emit(GameError('Error creating match: $e'));
    }
  }

  Future<void> _onJoinMatch(
    JoinMatchEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading(message: 'Joining match...'));

    try {
      // The menu screen already validated and resolved the match ID,
      // so we just join directly.
      _currentMatchId = event.matchId;
      await nakamaService.joinMatch(event.matchId);

      emit(GameMatchCreated(matchId: event.matchId, shortCode: ''));
      debugPrint('Joined match: ${event.matchId}');
    } catch (e) {
      debugPrint('Error joining match: $e');
      emit(GameError('Error joining match: $e'));
    }
  }

  Future<void> _onMakeMove(
    MakeMoveEvent event,
    Emitter<GameState> emit,
  ) async {
    if (state is! GamePlaying) return;
    if (_movePending) return;

    final currentState = state as GamePlaying;
    if (!currentState.isMyTurn) return;

    if (!GameService.isValidMove(
      currentState.gameState.board,
      event.position,
    )) {
      return;
    }

    try {
      _movePending = true;
      await nakamaService.sendMove(event.position);
    } catch (e) {
      _movePending = false;
      emit(GameError('Failed to send move: $e'));
    }
  }

  void _onGameStateUpdate(
    GameStateUpdateEvent event,
    Emitter<GameState> emit,
  ) {
    try {
      // Server confirmed the state — clear the pending flag so the
      // next move can be sent.
      _movePending = false;

      final gameState = GameStateModel.fromJson(event.stateData);
      final matchId = _currentMatchId;

      if (matchId == null) {
        debugPrint('Received state update but no match ID set');
        return;
      }

      if (gameState.gameOver) {
        final didIWin = gameState.winnerId == userId;
        emit(
          GameOver(
            matchId: matchId,
            finalState: gameState,
            winnerId: gameState.winnerId,
            isDraw: gameState.isDraw,
            didIWin: didIWin,
          ),
        );
        return;
      }

      _mySymbol ??= gameState.getSymbolForUser(userId);

      if (_mySymbol == null) {
        debugPrint('Could not determine symbol for user: $userId');
        emit(const GameError('Could not determine player symbol'));
        return;
      }

      final isMyTurn = gameState.currentTurnId == userId;

      emit(
        GamePlaying(
          matchId: matchId,
          gameState: gameState,
          isMyTurn: isMyTurn,
          mySymbol: _mySymbol!,
        ),
      );

      // If it's my turn and only one empty cell remains, auto-play it.
      if (isMyTurn) {
        final emptyCells = <int>[];
        for (int i = 0; i < gameState.board.length; i++) {
          if (gameState.board[i].isEmpty) emptyCells.add(i);
        }
        if (emptyCells.length == 1) {
          add(MakeMoveEvent(emptyCells.first));
        }
      }
    } catch (e) {
      emit(GameError('Error processing game state: $e'));
    }
  }

  Future<void> _onRematch(
    RematchEvent event,
    Emitter<GameState> emit,
  ) async {
    await _onLeaveMatch(const LeaveMatchEvent(), emit);
    add(CreateMatchEvent(mode));
  }

  Future<void> _onLeaveMatch(
    LeaveMatchEvent event,
    Emitter<GameState> emit,
  ) async {
    try {
      await nakamaService.leaveMatch();
      _currentMatchId = null;
      _mySymbol = null;
      emit(const GameInitial());
    } catch (e) {
      emit(GameError('Error leaving match: $e'));
    }
  }

  void _onSendChatMessage(
    SendChatMessageEvent event,
    Emitter<GameState> emit,
  ) {
    nakamaService.sendChatMessage(event.message);
  }

  @override
  Future<void> close() {
    _matchStateSubscription?.cancel();
    // Leave the server-side match so the opponent gets notified.
    nakamaService.leaveMatch();
    return super.close();
  }
}
