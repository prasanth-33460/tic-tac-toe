import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../config/app_theme.dart';
import '../services/nakama_service.dart';
import 'matchmaking_screen.dart';
import 'leaderboard_screen.dart';

class MenuScreen extends StatelessWidget {
  final String username;
  final String userId;

  const MenuScreen({super.key, required this.username, required this.userId});

  @override
  Widget build(BuildContext context) {
    return _MenuContent(username: username, userId: userId);
  }
}

class _MenuContent extends StatefulWidget {
  final String username;
  final String userId;

  const _MenuContent({required this.username, required this.userId});

  @override
  State<_MenuContent> createState() => _MenuContentState();
}

class _MenuContentState extends State<_MenuContent> {
  final TextEditingController _matchIdController = TextEditingController();

  @override
  void dispose() {
    _matchIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome, ${widget.username}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'TIC TAC TOE',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 60),

                  const Text(
                    'Create New Match',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _MenuButton(
                    text: 'Classic Mode',
                    subtitle: 'Create match & share ID',
                    icon: Icons.add_circle,
                    onPressed: () => _createMatch(context, 'classic'),
                  ),
                  const SizedBox(height: 16),

                  _MenuButton(
                    text: 'Timed Mode',
                    subtitle: 'Create match & share ID',
                    icon: Icons.timer,
                    onPressed: () => _createMatch(context, 'timed'),
                    isPrimary: false,
                  ),
                  const SizedBox(height: 40),

                  Container(height: 1, color: Colors.grey[700]),
                  const SizedBox(height: 24),

                  const Text(
                    'Join Existing Match',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _matchIdController,
                    decoration: InputDecoration(
                      hintText: 'Enter Match ID',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _joinMatch(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
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

  void _createMatch(BuildContext context, String mode) {
    final nakamaService = context.read<NakamaService>();
    final actualUserId = nakamaService.userId ?? widget.userId;

    final gameBloc = GameBloc(
      nakamaService: nakamaService,
      userId: actualUserId,
      mode: mode,
    );
    gameBloc.add(CreateMatchEvent(mode));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: gameBloc,
          child: MatchmakingScreen(mode: mode),
        ),
      ),
    );
  }

  Future<void> _joinMatch(BuildContext context) async {
    final matchId = _matchIdController.text.trim();
    if (matchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Match ID')),
      );
      return;
    }

    final nakamaService = context.read<NakamaService>();

    // Validate the match exists before navigating.
    // Resolve short code to full ID if needed.
    String resolvedId = matchId;
    final isShortCode = RegExp(r'^\d{6}$').hasMatch(matchId);

    // Show a quick loading indicator.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking match...'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.surface,
      ),
    );

    if (isShortCode) {
      final resolved = await nakamaService.getMatchIdByCode(matchId);
      if (resolved == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Invalid match code'),
            backgroundColor: AppColors.danger,
          ));
        return;
      }
      resolvedId = resolved;
    } else {
      final exists = await nakamaService.matchExists(matchId);
      if (!exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Match not found'),
            backgroundColor: AppColors.danger,
          ));
        return;
      }
    }

    if (!context.mounted) return;

    // Match is valid — create bloc and navigate.
    final actualUserId = nakamaService.userId ?? widget.userId;
    final gameBloc = GameBloc(
      nakamaService: nakamaService,
      userId: actualUserId,
      mode: 'join',
    );
    gameBloc.add(JoinMatchEvent(resolvedId));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: gameBloc,
          child: const MatchmakingScreen(mode: 'join'),
        ),
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }
}

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
        color: isPrimary ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconSize,
                  color: isPrimary ? Colors.black : AppColors.primary,
                ),
                const SizedBox(width: 16),
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
                          color: isPrimary ? Colors.black : AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isPrimary ? Colors.black54 : Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
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
