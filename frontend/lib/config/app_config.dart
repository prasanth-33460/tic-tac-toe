class AppConfig {
  // Backend configuration
  static const String nakamaHost = '10.0.2.2';
  static const int nakamaPort = 7350;
  static const String nakamaServerKey = 'defaultkey';
  static const bool useSsl = false;

  // Game configuration
  static const int boardSize = 9;
  static const int maxPlayers = 2;
  static const Duration matchmakingTimeout = Duration(seconds: 30);

  // OpCodes - match the backend
  static const int opCodeMove = 1;
  static const int opCodeState = 2;
  static const int opCodeGameEnd = 3;

  // UI Configuration
  static const double gameBoardPadding = 12.0;
  static const double cellBorderRadius = 12.0;
}
