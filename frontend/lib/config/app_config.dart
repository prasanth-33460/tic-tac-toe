import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  // -- Server (loaded from env.config) --
  static String get nakamaHost {
    final envHost = dotenv.get('NAKAMA_HOST', fallback: 'localhost');

    if (envHost == 'localhost' || envHost == '10.0.2.2') {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return '10.0.2.2';
      }
      return 'localhost';
    }

    return envHost;
  }

  static int get nakamaPort =>
      int.parse(dotenv.get('NAKAMA_PORT', fallback: '7350'));
  static String get nakamaServerKey =>
      dotenv.get('NAKAMA_SERVER_KEY', fallback: 'defaultkey');
  static bool get useSsl =>
      dotenv.get('NAKAMA_SSL', fallback: 'false') == 'true';

  // -- Game rules --
  static const int boardSize = 9;
  static const int maxPlayers = 2;
  static const Duration matchmakingTimeout = Duration(seconds: 30);

  // -- Op-codes (must match backend match/constants.go) --
  static const int opCodeMove = 1;
  static const int opCodeState = 2;
  static const int opCodeGameEnd = 3;
  static const int opCodeChat = 5;
}
