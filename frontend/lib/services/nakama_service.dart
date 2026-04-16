import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nakama/nakama.dart';
import '../config/app_config.dart';
import '../models/match_model.dart';

class NakamaService {
  late final NakamaBaseClient _client;
  Session? _session;

  String? _currentMatchId;
  String? get currentMatchId => _currentMatchId;

  String? get userId => _session?.userId;

  StreamController<Map<String, dynamic>> _matchStateController =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamController<Map<String, dynamic>> _chatController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get matchStateStream =>
      _matchStateController.stream;

  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  // Track socket subscriptions so we can cancel them on reconnect.
  StreamSubscription? _matchDataSub;
  StreamSubscription? _matchPresenceSub;

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

      debugPrint('Authenticated: ${_session?.userId} as ${displayName ?? deviceId}');
      return _session != null;
    } catch (e) {
      debugPrint('Auth failed: $e');
      return false;
    }
  }

  Future<void> connectSocket() async {
    if (_session == null) {
      throw Exception('Must authenticate first');
    }

    // If the stream controller was previously closed (e.g. after logout),
    // create a fresh one so listeners can resubscribe.
    if (_matchStateController.isClosed) {
      _matchStateController =
          StreamController<Map<String, dynamic>>.broadcast();
    }
    if (_chatController.isClosed) {
      _chatController =
          StreamController<Map<String, dynamic>>.broadcast();
    }

    try {
      // Cancel any previous listeners to avoid duplicates on re-login.
      await _matchDataSub?.cancel();
      await _matchPresenceSub?.cancel();

      NakamaWebsocketClient.init(
        host: AppConfig.nakamaHost,
        ssl: AppConfig.useSsl,
        token: _session!.token,
      );

      final socket = NakamaWebsocketClient.instance;

      _matchDataSub = socket.onMatchData.listen((event) {
        _handleMatchData(event);
      });

      _matchPresenceSub = socket.onMatchPresence.listen((event) {
        debugPrint(
          'Match presence: ${event.joins.length} joined, ${event.leaves.length} left',
        );
      });

      // Give the backend a moment to fully initialize the connection.
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('Socket connected');
    } catch (e) {
      debugPrint('Socket connection failed: $e');
      rethrow;
    }
  }

  void _handleMatchData(MatchData data) {
    try {
      final dataBytes = data.data ?? [];
      if (dataBytes.isEmpty) return;

      final decoded = json.decode(utf8.decode(dataBytes));
      final opCode = data.opCode;

      if (opCode == AppConfig.opCodeState || opCode == AppConfig.opCodeGameEnd) {
        if (!_matchStateController.isClosed) {
          _matchStateController.add(decoded);
        }
      } else if (opCode == AppConfig.opCodeChat) {
        if (!_chatController.isClosed) {
          _chatController.add(decoded);
        }
      }
    } catch (e) {
      debugPrint('Error parsing match data: $e');
    }
  }

  // Match creation / lookup

  Future<MatchModel?> findMatch({String mode = 'classic'}) async {
    if (_session == null) return null;

    return _retryRpc<MatchModel>(
      label: 'findMatch',
      rpcCall: () => NakamaWebsocketClient.instance.rpc(
        id: 'find_match',
        payload: json.encode({'mode': mode}),
      ),
      parsePayload: (payload) {
        final data = json.decode(payload);
        final model = MatchModel.fromJson(data);
        _currentMatchId = model.matchId;
        return model;
      },
    );
  }

  Future<MatchModel?> createQuickMatch() async {
    if (_session == null) return null;

    return _retryRpc<MatchModel>(
      label: 'createQuickMatch',
      rpcCall: () => NakamaWebsocketClient.instance.rpc(
        id: 'create_quick_match',
        payload: '',
      ),
      parsePayload: (payload) {
        final data = json.decode(payload);
        final model = MatchModel.fromJson(data);
        _currentMatchId = model.matchId;
        return model;
      },
    );
  }

  Future<String?> getMatchIdByCode(String code) async {
    if (_session == null) return null;

    try {
      final result = await NakamaWebsocketClient.instance.rpc(
        id: 'get_match_by_code',
        payload: json.encode({'code': code}),
      );

      final payload = result.payload;
      if (payload.isEmpty) return null;

      final data = json.decode(payload);
      return data['matchId'];
    } catch (e) {
      debugPrint('Error getting match by code: $e');
      return null;
    }
  }

  Future<bool> matchExists(String matchId) async {
    if (_session == null) return false;

    try {
      await NakamaWebsocketClient.instance.rpc(
        id: 'get_match_info',
        payload: json.encode({'matchId': matchId}),
      );
      return true;
    } catch (e) {
      debugPrint('Match does not exist: $matchId');
      return false;
    }
  }

  // In-match operations

  Future<void> joinMatch(String matchId) async {
    try {
      final socket = NakamaWebsocketClient.instance;
      await socket.joinMatch(matchId);
      _currentMatchId = matchId;
      debugPrint('Joined match: $matchId');
    } catch (e) {
      debugPrint('Join match failed: $e');
      rethrow;
    }
  }

  Future<void> sendMove(int position) async {
    if (_currentMatchId == null) {
      throw Exception('Not in a match');
    }

    try {
      final moveData = json.encode({'position': position});

      NakamaWebsocketClient.instance.sendMatchData(
        matchId: _currentMatchId!,
        opCode: AppConfig.opCodeMove,
        data: utf8.encode(moveData),
      );
    } catch (e) {
      debugPrint('Send move failed: $e');
      rethrow;
    }
  }

  void sendChatMessage(String message) {
    if (_currentMatchId == null) return;

    final chatData = json.encode({'message': message});

    NakamaWebsocketClient.instance.sendMatchData(
      matchId: _currentMatchId!,
      opCode: AppConfig.opCodeChat,
      data: utf8.encode(chatData),
    );
  }

  Future<void> leaveMatch() async {
    if (_currentMatchId == null) return;

    try {
      final socket = NakamaWebsocketClient.instance;
      await socket.leaveMatch(_currentMatchId!);
      debugPrint('Left match: $_currentMatchId');
      _currentMatchId = null;
    } catch (e) {
      debugPrint('Leave match failed: $e');
      _currentMatchId = null;
    }
  }

  // Leaderboard

  Future<Map<String, dynamic>> getLeaderboard() async {
    if (_session == null) return {};

    final result = await _retryRpc<Map<String, dynamic>>(
      label: 'getLeaderboard',
      rpcCall: () => NakamaWebsocketClient.instance.rpc(
        id: 'get_leaderboard',
        payload: '',
      ),
      parsePayload: (payload) => json.decode(payload),
    );

    return result ?? {};
  }

  // Lifecycle

  Future<void> disconnect() async {
    await _matchDataSub?.cancel();
    await _matchPresenceSub?.cancel();
    _matchDataSub = null;
    _matchPresenceSub = null;

    try {
      NakamaWebsocketClient.instance.close();
    } catch (e) {
      debugPrint('Error closing socket: $e');
    }
    _session = null;
    _currentMatchId = null;
    debugPrint('Disconnected');
  }

  void dispose() {
    _matchDataSub?.cancel();
    _matchPresenceSub?.cancel();
    _matchStateController.close();
    _chatController.close();
  }

  // Helpers

  /// Retries an RPC call up to [maxAttempts] times with linear backoff.
  Future<T?> _retryRpc<T>({
    required String label,
    required Future<Rpc> Function() rpcCall,
    required T Function(String payload) parsePayload,
    int maxAttempts = 3,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await rpcCall();
        final payload = result.payload;

        if (payload.isEmpty) {
          debugPrint('$label attempt $attempt: empty payload');
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(seconds: attempt));
          }
          continue;
        }

        return parsePayload(payload);
      } catch (e) {
        debugPrint('$label attempt $attempt failed: $e');

        if (attempt == maxAttempts) return null;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return null;
  }
}
