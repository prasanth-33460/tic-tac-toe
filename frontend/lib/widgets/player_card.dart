import 'package:flutter/material.dart';

/// Player Card Widget - Shows player info
/// Thought: "Display player symbol, name, and active indicator"
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF00D4FF).withOpacity(0.2)
            : const Color(0xFF1A1F27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF00D4FF) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Symbol
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getSymbolColor().withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _getSymbolColor(), width: 2),
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _getSymbolColor(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (isActive)
                  const Text(
                    'Your turn',
                    style: TextStyle(fontSize: 12, color: Color(0xFF00D4FF)),
                  ),
              ],
            ),
          ),

          // Active indicator
          if (isActive)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.5),
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

  Color _getSymbolColor() {
    return symbol == 'X' ? const Color(0xFF00D4FF) : Colors.red;
  }
}
