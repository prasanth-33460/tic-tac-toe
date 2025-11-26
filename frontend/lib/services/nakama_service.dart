import 'dart:async';
import 'dart:convert';
import 'package:nakama/nakama.dart';
import '../config/app_config.dart';
import '../models/match_model.dart';

class NakamaService {
  late final NakamaBaseClient _client;
  Session? _session;

  String? _currentMatchId;
  String? get currentMatchId => _currentMatchId;

  // Get the authenticated user's Nakama user ID
  String? get userId => _session?.userId;

  final StreamController<Map<String, dynamic>> _matchStateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get matchStateStream =>
      _matchStateController.stream;

  final StreamController<MatchmakerMatched> _matchmakerMatchedController =
      StreamController<MatchmakerMatched>.broadcast();

  Stream<MatchmakerMatched> get matchmakerMatchedStream =>
      _matchmakerMatchedController.stream;

  NakamaService() {
    _initializeClient();
  }

  void _initializeClient() {
    _client = getNakamaClient(
      host: AppConfig.nakamaHost,
      ssl: AppConfig.useSsl,
      serverKey: AppConfig.nakamaServerKey,
      httpPort: AppConfig.nakamaPort,
    );
  }

  Future<bool> authenticateDevice(
    String deviceId, {
    String? displayName,
  }) async {
    try {
      _session = await _client.authenticateDevice(
        deviceId: deviceId,
        create: true,
        username: displayName ?? deviceId,
      );

      print(
        '✅ Authenticated: ${_session?.userId} with display name: ${displayName ?? deviceId}',
      );
      return _session != null;
    } catch (e) {
      print('❌ Auth failed: $e');
      return false;
    }
  }

  Future<void> connectSocket() async {
    if (_session == null) {
      throw Exception('Must authenticate first');
    }

    try {
      NakamaWebsocketClient.init(
        host: AppConfig.nakamaHost,
        ssl: AppConfig.useSsl,
        token: _session!.token,
      );

      final socket = NakamaWebsocketClient.instance;

      socket.onMatchData.listen((event) {
        _handleMatchData(event);
      });

      socket.onMatchPresence.listen((event) {
        print(
          'Match presence: ${event.joins.length} joined, ${event.leaves.length} left',
        );
      });

      socket.onMatchmakerMatched.listen((event) {
        print('✅ Matchmaker matched: ${event.matchId}');
        _matchmakerMatchedController.add(event);
      });

      // ✅ WAIT FOR BACKEND TO BE FULLY READY
      print('⏳ Waiting for backend to initialize...');
      await Future.delayed(const Duration(seconds: 2));

      print('✅ Socket connected');
    } catch (e) {
      print('❌ Socket connection failed: $e');
      rethrow;
    }
  }

  String? _matchmakerTicket;

  Future<void> startMatchmaking({String mode = 'classic'}) async {
    if (_session == null) return;

    if (_matchmakerTicket != null) {
      try {
        await cancelMatchmaking();
      } catch (e) {
        print('⚠️ Failed to cancel previous matchmaking ticket: $e');
        // Continue anyway to try creating a new ticket
      }
    }

    try {
      final socket = NakamaWebsocketClient.instance;
      final ticket = await socket.addMatchmaker(
        minCount: 2,
        maxCount: 2,
        query: '*',
        stringProperties: {'mode': mode},
      );
      _matchmakerTicket = ticket.ticket;
      print('✅ Added to matchmaker (mode: $mode), ticket: $_matchmakerTicket');
    } catch (e) {
      print('❌ Failed to add to matchmaker: $e');
      rethrow;
    }
  }

  Future<void> cancelMatchmaking() async {
    if (_session == null || _matchmakerTicket == null) return;

    try {
      final socket = NakamaWebsocketClient.instance;
      await socket.removeMatchmaker(_matchmakerTicket!);
      print('✅ Removed from matchmaker: $_matchmakerTicket');
      _matchmakerTicket = null;
    } catch (e) {
      print('❌ Failed to remove from matchmaker: $e');
    }
  }

  void _handleMatchData(MatchData data) {
    try {
      final dataBytes = data.data ?? [];
      if (dataBytes.isEmpty) return;

      final stateJson = json.decode(utf8.decode(dataBytes));
      _matchStateController.add(stateJson);
    } catch (e) {
      print('Error parsing match data: $e');
    }
  }

  Future<MatchModel?> createQuickMatch() async {
    if (_session == null) return null;

    // ✅ RETRY LOGIC: Try up to 3 times with exponential backoff
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('🔄 Attempt $attempt to create match...');

        final result = await NakamaWebsocketClient.instance.rpc(
          id: 'create_quick_match',
          payload: '',
        );

        final payload = result.payload;
        if (payload.isEmpty) {
          print('⚠️ Attempt $attempt: Empty payload, retrying...');

          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
          }
          continue;
        }

        try {
          final responseData = json.decode(payload);
          print('✅ Match created on attempt $attempt: $responseData');

          final matchModel = MatchModel.fromJson(responseData);
          _currentMatchId = matchModel.matchId;

          return matchModel;
        } catch (parseError) {
          print('❌ Parse error on attempt $attempt: $parseError');
          print('Response was: $payload');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
          }
          continue;
        }
      } catch (e) {
        print('❌ RPC error on attempt $attempt: $e');

        if (attempt == 3) {
          print('❌ All 3 attempts failed');
          return null;
        }

        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return null;
  }

  Future<MatchModel?> findMatch({String mode = 'classic'}) async {
    if (_session == null) return null;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('🔄 Attempt $attempt to find match with mode: $mode...');

        final result = await NakamaWebsocketClient.instance.rpc(
          id: 'find_match',
          payload: json.encode({'mode': mode}),
        );

        final payload = result.payload;
        if (payload.isEmpty) {
          print('⚠️ Attempt $attempt: Empty payload, retrying...');

          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
          }
          continue;
        }

        try {
          final responseData = json.decode(payload);
          print('✅ Match found on attempt $attempt: $responseData');

          final matchModel = MatchModel.fromJson(responseData);
          _currentMatchId = matchModel.matchId;

          return matchModel;
        } catch (parseError) {
          print('❌ Parse error on attempt $attempt: $parseError');
          print('Response was: $payload');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
          }
          continue;
        }
      } catch (e) {
        print('❌ RPC error on attempt $attempt: $e');

        if (attempt == 3) {
          print('❌ All 3 attempts failed');
          return null;
        }

        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return null;
  }

  Future<String?> getMatchIdByCode(String code) async {
    if (_session == null) return null;

    try {
      final result = await NakamaWebsocketClient.instance.rpc(
        id: 'get_match_by_code',
        payload: json.encode({'code': code}),
      );

      final payload = result.payload;
      if (payload.isEmpty) {
        print('⚠️ Empty payload from get_match_by_code');
        return null;
      }

      final responseData = json.decode(payload);
      return responseData['matchId'];
    } catch (e) {
      print('❌ Error getting match ID by code: $e');
      return null;
    }
  }

  Future<bool> matchExists(String matchId) async {
    if (_session == null) return false;

    try {
      // Try to get match info - if it fails, match doesn't exist
      await NakamaWebsocketClient.instance.rpc(
        id: 'get_match_info',
        payload: json.encode({'matchId': matchId}),
      );
      return true;
    } catch (e) {
      print('❌ Match does not exist: $matchId');
      return false;
    }
  }

  Future<void> joinMatch(String matchId) async {
    try {
      final socket = NakamaWebsocketClient.instance;
      await socket.joinMatch(matchId);
      _currentMatchId = matchId;
      print('✅ Joined match: $matchId');
    } catch (e) {
      print('❌ Join match failed: $e');
      rethrow;
    }
  }

  Future<void> sendMove(int position) async {
    if (_currentMatchId == null) {
      throw Exception('Not in a match');
    }

    try {
      final moveData = json.encode({'position': position});

      final socket = NakamaWebsocketClient.instance;
      socket.sendMatchData(
        matchId: _currentMatchId!,
        opCode: AppConfig.opCodeMove,
        data: utf8.encode(moveData),
      );

      print('✅ Sent move: position $position');
    } catch (e) {
      print('❌ Send move failed: $e');
      rethrow;
    }
  }

  Future<void> sendRematch() async {
    if (_currentMatchId == null) {
      throw Exception('Not in a match');
    }

    try {
      final socket = NakamaWebsocketClient.instance;
      socket.sendMatchData(
        matchId: _currentMatchId!,
        opCode: AppConfig.opCodeRematch,
        data: [],
      );

      print('✅ Sent rematch request');
    } catch (e) {
      print('❌ Send rematch failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLeaderboard() async {
    if (_session == null) return {};

    // ✅ RETRY LOGIC: Try up to 3 times with exponential backoff
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('🔄 Attempt $attempt to fetch leaderboard...');

        final result = await NakamaWebsocketClient.instance.rpc(
          id: 'get_leaderboard',
          payload: '',
        );

        final payload = result.payload;
        if (payload.isEmpty) {
          print('⚠️ Attempt $attempt: Empty payload, retrying...');

          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
          }
          continue;
        }

        try {
          final data = json.decode(payload);
          print('✅ Leaderboard fetched on attempt $attempt');
          return data;
        } catch (parseError) {
          print('❌ Parse error on attempt $attempt: $parseError');
          print('Response was: $payload');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
          }
          continue;
        }
      } catch (e) {
        print('❌ RPC error on attempt $attempt: $e');

        if (attempt == 3) {
          print('❌ All 3 attempts failed');
          return {};
        }

        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return {};
  }

  Future<void> leaveMatch() async {
    if (_currentMatchId != null) {
      try {
        final socket = NakamaWebsocketClient.instance;
        await socket.leaveMatch(_currentMatchId!);
        _currentMatchId = null;
        print('✅ Left match');
      } catch (e) {
        print('❌ Leave match failed: $e');
      }
    }
  }

  Future<void> disconnect() async {
    try {
      NakamaWebsocketClient.instance.close();
    } catch (e) {
      print('Error closing socket: $e');
    }
    await _matchStateController.close();
    _session = null;
    print('✅ Disconnected');
  }

  void dispose() {
    _matchStateController.close();
  }
}
