import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nakama/nakama.dart';
import '../../models/game_state_model.dart';
import '../../services/nakama_service.dart';
import '../../services/game_service.dart';
import 'game_event.dart';
import 'game_state.dart';

/// Game BLoC - handles all game logic
/// Thought: "This is complex - manages match lifecycle, moves, state updates"
class GameBloc extends Bloc<GameEvent, GameState> {
  final NakamaService nakamaService;
  final String userId; // My user ID
  final String mode; // Game mode: classic or timed

  String? _currentMatchId;
  String? _mySymbol;
  StreamSubscription<Map<String, dynamic>>? _matchStateSubscription;
  StreamSubscription<MatchmakerMatched>? _matchmakerSubscription;

  GameBloc({
    required this.nakamaService,
    required this.userId,
    required this.mode,
  }) : super(const GameInitial()) {
    debugPrint('🎮 GameBloc initialized for user: $userId');
    // Register event handlers
    on<CreateMatchEvent>(_onCreateMatch);
    on<FindMatchEvent>(_onFindMatch);
    on<JoinMatchEvent>(_onJoinMatch);
    on<MatchJoinedEvent>(_onMatchJoined);
    on<MatchFoundEvent>(_onMatchFound);
    on<MakeMoveEvent>(_onMakeMove);
    on<GameStateUpdateEvent>(_onGameStateUpdate);
    on<GameEndedEvent>(_onGameEnded);
    on<RematchEvent>(_onRematch);
    on<LeaveMatchEvent>(_onLeaveMatch);
    debugPrint('📋 GameBloc event handlers registered');

    // Listen to match state updates from server
    _subscribeToMatchUpdates();
  }

  /// Subscribe to real-time match updates
  /// Thought: "Server sends updates -> convert to events"
  void _subscribeToMatchUpdates() {
    debugPrint('📡 Setting up match state subscription');
    _matchStateSubscription = nakamaService.matchStateStream.listen((data) {
      debugPrint('📨 Received match state update: ${data.keys.join(", ")}');
      add(GameStateUpdateEvent(data));
    });

    _matchmakerSubscription = nakamaService.matchmakerMatchedStream.listen((
      event,
    ) {
      debugPrint('🎯 Matchmaker matched event received');

      String? matchId = event.matchId;

      // Fallback: Extract match ID from token if matchId is null or empty
      if ((matchId == null || matchId.isEmpty) && event.token != null) {
        debugPrint(
          '⚠️ matchId is null or empty, attempting to extract from token',
        );
        try {
          final parts = event.token!.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final resp = utf8.decode(base64Url.decode(normalized));
            final payloadMap = json.decode(resp) as Map<String, dynamic>;
            final mid = payloadMap['mid'];
            if (mid is String && mid.isNotEmpty) {
              matchId = mid;
              debugPrint('✅ Extracted matchId from token: $matchId');
            }
          }
        } catch (e) {
          debugPrint('❌ Error decoding token: $e');
        }
      }

      if (matchId != null && matchId.isNotEmpty) {
        debugPrint('🎯 Match found: $matchId');
        add(MatchFoundEvent(matchId));
      } else {
        debugPrint('❌ Failed to get match ID from matchmaker event');
      }
    });

    debugPrint('✅ Match state subscription active');
  }

  /// Handle create match event
  /// Thought: "User wants to create a new match"
  Future<void> _onCreateMatch(
    CreateMatchEvent event,
    Emitter<GameState> emit,
  ) async {
    debugPrint('🎯 Handling CreateMatchEvent with mode: ${event.mode}');
    emit(const GameLoading(message: 'Creating match...'));

    try {
      // Call backend to create match with mode
      final match = await nakamaService.findMatch(mode: event.mode);

      if (match != null) {
        _currentMatchId = match.matchId;
        debugPrint('✅ Match created successfully: ${match.matchId}');

        // Join the match via WebSocket
        await nakamaService.joinMatch(match.matchId);
        debugPrint('🔗 Joined match via WebSocket');

        // Show match created state with ID for sharing
        emit(
          GameMatchCreated(matchId: match.matchId, shortCode: match.shortCode),
        );
        debugPrint(
          '🎉 Match created - waiting for opponent to join via match ID',
        );
      } else {
        debugPrint('❌ Failed to create match - null response');
        emit(const GameError('Failed to create match'));
      }
    } catch (e) {
      debugPrint('💥 Error creating match: $e');
      emit(GameError('Error creating match: $e'));
    }
  }

  /// Handle find match event (auto matchmaking)
  Future<void> _onFindMatch(
    FindMatchEvent event,
    Emitter<GameState> emit,
  ) async {
    debugPrint('🎯 Handling FindMatchEvent with mode: ${event.mode}');
    emit(GameSearching(mode: event.mode));

    try {
      await nakamaService.startMatchmaking(mode: event.mode);
      debugPrint('✅ Started matchmaking');
    } catch (e) {
      debugPrint('💥 Error starting matchmaking: $e');
      emit(GameError('Error starting matchmaking: $e'));
    }
  }

  /// Handle match found event
  Future<void> _onMatchFound(
    MatchFoundEvent event,
    Emitter<GameState> emit,
  ) async {
    debugPrint('🎯 Handling MatchFoundEvent: ${event.matchId}');
    _currentMatchId = event.matchId;

    try {
      // Join the match via WebSocket
      await nakamaService.joinMatch(event.matchId);
      debugPrint('🔗 Joined match via WebSocket');

      emit(const GameLoading(message: 'Match found! Joining...'));
    } catch (e) {
      debugPrint('💥 Error joining found match: $e');
      emit(GameError('Error joining match: $e'));
    }
  }

  /// Handle join match event
  /// Thought: "User wants to join a specific match"
  Future<void> _onJoinMatch(
    JoinMatchEvent event,
    Emitter<GameState> emit,
  ) async {
    debugPrint('🎯 Handling JoinMatchEvent for ${event.matchId}');
    emit(const GameLoading(message: 'Joining match...'));

    try {
      String matchId = event.matchId;
      String shortCode = '';

      // Check if it's a short code (6 digits)
      if (RegExp(r'^\d{6}$').hasMatch(event.matchId)) {
        debugPrint('🔍 Detected short code, resolving to match ID...');
        final resolvedMatchId = await nakamaService.getMatchIdByCode(
          event.matchId,
        );
        if (resolvedMatchId == null) {
          emit(const GameError('Invalid match code'));
          return;
        }
        matchId = resolvedMatchId;
        shortCode = event.matchId;
        debugPrint(
          '✅ Resolved short code ${event.matchId} to match ID $matchId',
        );
      } else {
        // For direct match IDs, check if the match exists
        debugPrint('🔍 Checking if match exists: $matchId');
        final exists = await nakamaService.matchExists(matchId);
        if (!exists) {
          emit(const GameError('Match not found'));
          return;
        }
        debugPrint('✅ Match exists: $matchId');
      }

      _currentMatchId = matchId;
      debugPrint('✅ Match ID set: $matchId');

      // Join the match via WebSocket
      await nakamaService.joinMatch(matchId);
      debugPrint('🔗 Joined match via WebSocket');

      // Enter waiting state (match already exists)
      emit(GameMatchCreated(matchId: matchId, shortCode: shortCode));
      debugPrint('⏳ Entered match waiting state - waiting for game to start');
    } catch (e) {
      debugPrint('💥 Error joining match: $e');
      emit(GameError('Error joining match: $e'));
    }
  }

  /// Handle match joined event
  /// Thought: "Both players present, game starts"
  Future<void> _onMatchJoined(
    MatchJoinedEvent event,
    Emitter<GameState> emit,
  ) async {
    // Game will start when we receive first state update
  }

  /// Handle make move event
  /// Thought: "User tapped a cell, send move to server"
  Future<void> _onMakeMove(MakeMoveEvent event, Emitter<GameState> emit) async {
    debugPrint('🎯 Handling MakeMoveEvent at position: ${event.position}');
    debugPrint('Current State Type: ${state.runtimeType}');

    // Only allow moves if it's our turn
    if (state is! GamePlaying) {
      debugPrint('❌ Cannot make move: Game not in playing state. Current state: $state');
      return;
    }

    final currentState = state as GamePlaying;
    debugPrint('Current Turn ID: ${currentState.gameState.currentTurnId}');
    debugPrint('My Symbol: ${currentState.mySymbol}');
    debugPrint('Is My Turn: ${currentState.isMyTurn}');
    
    if (!currentState.isMyTurn) {
      debugPrint('❌ Cannot make move: Not my turn');
      return;
    }

    // Validate move locally first
    if (!GameService.isValidMove(
      currentState.gameState.board,
      event.position,
    )) {
      debugPrint('❌ Invalid move at position ${event.position}. Board: ${currentState.gameState.board}');
      return;
    }

    try {
      debugPrint('🚀 Sending move to server: ${event.position}');
      // Send move to server
      await nakamaService.sendMove(event.position);
      debugPrint('✅ Move sent successfully');
      // Server will send back updated state
    } catch (e) {
      debugPrint('💥 Error sending move: $e');
      emit(GameError('Failed to send move: $e'));
    }
  }

  /// Handle game state update from server
  /// Thought: "Server sent new game state, update UI"
  void _onGameStateUpdate(GameStateUpdateEvent event, Emitter<GameState> emit) {
    debugPrint('🔄 Processing GameStateUpdateEvent');
    try {
      debugPrint('Raw State Data: ${event.stateData}');
      final gameState = GameStateModel.fromJson(event.stateData);
      debugPrint('Parsed GameState: $gameState');

      // Check if game is over
      if (gameState.gameOver) {
        debugPrint('🏁 Game Over detected. Winner: ${gameState.winnerId}');
        final didIWin = gameState.winnerId == userId;

        emit(
          GameOver(
            matchId: _currentMatchId!,
            finalState: gameState,
            winnerId: gameState.winnerId,
            isDraw: gameState.isDraw,
            didIWin: didIWin,
          ),
        );
        return;
      }

      // Get my symbol directly from the players data
      // Robustness: Check if userId matches, if not try nakamaService.userId
      var effectiveUserId = userId;
      debugPrint('Checking symbol for userId: $userId');
      var symbol = gameState.getSymbolForUser(effectiveUserId);
      
      if (symbol == null && nakamaService.userId != null) {
        debugPrint('⚠️ userId $userId not found in players, trying nakamaService.userId: ${nakamaService.userId}');
        effectiveUserId = nakamaService.userId!;
        symbol = gameState.getSymbolForUser(effectiveUserId);
      }

      _mySymbol ??= symbol;
      debugPrint('Resolved Symbol: $_mySymbol');

      if (_mySymbol == null) {
        debugPrint('❌ Could not determine player symbol for user: $userId (or $effectiveUserId)');
        debugPrint('Players: ${gameState.players}');
        emit(const GameError('Could not determine player symbol'));
        return;
      }

      debugPrint(
        '✅ My symbol: $_mySymbol, isMyTurn: ${gameState.currentTurnId == effectiveUserId}',
      );
      debugPrint('Current Turn ID: ${gameState.currentTurnId}, My ID: $effectiveUserId');

      final isMyTurn = gameState.currentTurnId == effectiveUserId;
      debugPrint('Calculated isMyTurn: $isMyTurn');

      emit(
        GamePlaying(
          matchId: _currentMatchId!,
          gameState: gameState,
          isMyTurn: isMyTurn,
          mySymbol: _mySymbol!,
        ),
      );
      debugPrint('✅ Emitted GamePlaying state');
    } catch (e, stack) {
      debugPrint('💥 Error processing game state: $e');
      debugPrint('Stack trace: $stack');
      emit(GameError('Error processing game state: $e'));
    }
  }

  /// Handle game ended event
  /// Thought: "Game finished, show results"
  Future<void> _onGameEnded(
    GameEndedEvent event,
    Emitter<GameState> emit,
  ) async {
    // This is handled in _onGameStateUpdate
  }

  /// Handle rematch event
  /// Thought: "User wants to play again"
  Future<void> _onRematch(RematchEvent event, Emitter<GameState> emit) async {
    try {
      await nakamaService.sendRematch();
      // Don't emit state change yet, wait for server response
      // But we could emit a "Waiting for opponent" state if we had one
    } catch (e) {
      emit(GameError('Error requesting rematch: $e'));
    }
  }

  /// Handle leave match event
  /// Thought: "User quit, clean up"
  Future<void> _onLeaveMatch(
    LeaveMatchEvent event,
    Emitter<GameState> emit,
  ) async {
    try {
      if (state is GameSearching) {
        await nakamaService.cancelMatchmaking();
      }
      await nakamaService.leaveMatch();
      _currentMatchId = null;
      _mySymbol = null;
      emit(const GameInitial());
    } catch (e) {
      emit(GameError('Error leaving match: $e'));
    }
  }

  @override
  Future<void> close() {
    debugPrint('🧹 GameBloc closing - cleaning up resources');
    _matchStateSubscription?.cancel();
    _matchmakerSubscription?.cancel();
    debugPrint('✅ Match state subscription cancelled');
    return super.close();
  }
}
