import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../services/nakama_service.dart';
import 'matchmaking_screen.dart';
import 'leaderboard_screen.dart';

class MenuScreen extends StatelessWidget {
  final String username;
  final String userId;

  const MenuScreen({Key? key, required this.username, required this.userId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 MenuScreen building for user: $username ($userId)');
    // ✅ FIXED: Don't create GameBloc here, create it per match
    return MenuContent(username: username, userId: userId);
  }
}

/// Separate widget
class MenuContent extends StatefulWidget {
  final String username;
  final String userId;

  const MenuContent({Key? key, required this.username, required this.userId})
    : super(key: key);

  @override
  State<MenuContent> createState() => _MenuContentState();
}

class _MenuContentState extends State<MenuContent> {
  final TextEditingController _matchIdController = TextEditingController();

  @override
  void dispose() {
    _matchIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 MenuContent building UI');
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome message
                  Text(
                    'Welcome, ${widget.username}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Tic Tac Toe title
                  const Text(
                    'TIC TAC TOE',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D4FF),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Game Mode Section Header
                  const Text(
                    'Play Online',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Find Match Button
                  _MenuButton(
                    text: 'Find Match',
                    subtitle: 'Auto-match with random player',
                    icon: Icons.search,
                    onPressed: () => _findMatch(context, 'classic'),
                  ),
                  const SizedBox(height: 16),

                  // Create Match Section
                  const Text(
                    'Create Private Match',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Classic Mode Button
                  _MenuButton(
                    text: 'Classic Mode',
                    subtitle: 'Create match & share ID',
                    icon: Icons.add_circle,
                    onPressed: () => _createMatch(context, 'classic'),
                    isPrimary: false,
                  ),
                  const SizedBox(height: 16),

                  // Timed Mode Button
                  _MenuButton(
                    text: 'Timed Mode',
                    subtitle: 'Create match & share ID',
                    icon: Icons.timer,
                    onPressed: () => _createMatch(context, 'timed'),
                    isPrimary: false,
                  ),
                  const SizedBox(height: 40),

                  // Divider
                  Container(height: 1, color: Colors.grey[700]),
                  const SizedBox(height: 24),

                  // Join Match Section
                  const Text(
                    'Join Existing Match',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Match ID Text Field
                  TextField(
                    controller: _matchIdController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Match ID',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF1A1F27),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFF00D4FF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFF00D4FF)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Join Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _joinMatch(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Join Match',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Leaderboard Button
                  _MenuButton(
                    text: 'Leaderboard',
                    subtitle: 'Top players',
                    icon: Icons.leaderboard,
                    onPressed: () => _showLeaderboard(context),
                    isPrimary: false,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ FIXED: Create fresh GameBloc for each match
  void _createMatch(BuildContext context, String mode) {
    debugPrint('🎯 Creating match with mode: $mode for user: ${widget.userId}');

    final nakamaService = context.read<NakamaService>();
    final actualUserId = nakamaService.userId ?? widget.userId;

    // Navigate with new bloc
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => GameBloc(
            nakamaService: nakamaService,
            userId: actualUserId,
            mode: mode,
          )..add(CreateMatchEvent(mode)),
          child: MatchmakingScreen(mode: mode),
        ),
      ),
    );
    debugPrint('🧭 Navigated to MatchmakingScreen with mode: $mode');
  }

  void _joinMatch(BuildContext context) {
    final matchId = _matchIdController.text.trim();
    if (matchId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a Match ID')));
      return;
    }
    debugPrint('🎯 Joining match: $matchId');

    final nakamaService = context.read<NakamaService>();
    final actualUserId = nakamaService.userId ?? widget.userId;

    // Navigate with new bloc
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => GameBloc(
            nakamaService: nakamaService,
            userId: actualUserId,
            mode: 'join', // Will be determined from match data
          )..add(JoinMatchEvent(matchId)),
          child: MatchmakingScreen(mode: 'join'),
        ),
      ),
    );
    debugPrint('🧭 Navigated to MatchmakingScreen for join');
  }

  void _findMatch(BuildContext context, String mode) {
    debugPrint('🎯 Finding match with mode: $mode');

    final nakamaService = context.read<NakamaService>();
    final actualUserId = nakamaService.userId ?? widget.userId;

    // Navigate with new bloc
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => GameBloc(
            nakamaService: nakamaService,
            userId: actualUserId,
            mode: mode,
          )..add(FindMatchEvent(mode)),
          child: MatchmakingScreen(mode: mode),
        ),
      ),
    );
  }

  /// Show leaderboard screen
  void _showLeaderboard(BuildContext context) {
    debugPrint('📊 Navigating to LeaderboardScreen');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
    debugPrint('✅ LeaderboardScreen navigation completed');
  }
}

/// Custom menu button widget with subtitle
class _MenuButton extends StatelessWidget {
  final String text;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _MenuButton({
    required this.text,
    this.subtitle,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: Material(
        color: isPrimary ? const Color(0xFF00D4FF) : const Color(0xFF1A1F27),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Icon
                Icon(
                  icon,
                  size: 32,
                  color: isPrimary ? Colors.black : const Color(0xFF00D4FF),
                ),
                const SizedBox(width: 16),

                // Text and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isPrimary ? Colors.black : Colors.white,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isPrimary
                                ? Colors.black54
                                : Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward,
                  size: 24,
                  color: isPrimary ? Colors.black : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
