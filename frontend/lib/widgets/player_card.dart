import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PlayerCard extends StatelessWidget {
  final String symbol;
  final bool isActive;
  final String username;
  final bool isMe;

  const PlayerCard({
    super.key,
    required this.symbol,
    required this.isActive,
    required this.username,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final symbolColor = symbol == 'X' ? AppColors.primary : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.transparent,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: symbolColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: symbolColor, width: AppSizes.borderWidth),
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: symbolColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isActive)
                  Text(
                    isMe ? 'Your turn' : 'Their turn',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
              ],
            ),
          ),

          if (isActive)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
