// ============================================================
// lib/widgets/rewarded_ai_widget.dart
// AI screen mein — "5 aur sawaal chahiye? Ad dekho"
// ============================================================

import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

class RewardedAiButton extends StatefulWidget {
  final VoidCallback onUnlocked; // call when reward earned
  const RewardedAiButton({super.key, required this.onUnlocked});

  @override
  State<RewardedAiButton> createState() => _RewardedAiButtonState();
}

class _RewardedAiButtonState extends State<RewardedAiButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.saffron.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle_outline_rounded,
                color: AppTheme.saffron, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5 aur sawaal unlock karo',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ek short ad dekho — free mein',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              AdService().showRewardedForAiMessages(
                onRewarded: widget.onUnlocked,
                onFailed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ad abhi available nahi — thodi der mein try karo'),
                      backgroundColor: AppTheme.navyLight,
                    ),
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.saffron,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Dekho',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
