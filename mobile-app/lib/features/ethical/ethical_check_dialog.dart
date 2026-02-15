import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

/// Ethical check dialog — matches web app's ethical-check-modal.tsx
/// Shows weekly to ask if the app prevented a regretted purchase.
class EthicalCheckDialog {
  static const _key = 'mindspend_last_ethical_check';
  static const _weekInMs = 7 * 24 * 60 * 60 * 1000;

  /// Shows the dialog if a week has passed since last check
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_key) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastCheck < _weekInMs) return;

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EthicalCheckContent(
        onAnswer: (answer) {
          Navigator.of(ctx).pop(answer);
        },
      ),
    );

    if (result != null) {
      await prefs.setInt(_key, now);
    }
  }
}

class _EthicalCheckContent extends StatelessWidget {
  final Function(bool) onAnswer;

  const _EthicalCheckContent({required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.heart,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Weekly Check-In',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'In the past week, did MindSpend help you avoid a purchase you would have regretted?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ext.mutedForeground,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAnswer(false),
                  child: const Text('Not really'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onAnswer(true),
                  child: const Text('Yes, it did!'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This is for ethical tracking only — your answer stays private.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ext.mutedForeground.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
