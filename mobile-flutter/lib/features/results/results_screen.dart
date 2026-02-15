import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/purchase_history.dart';
import '../../api/purchase_service.dart';
import '../../utils/calculations.dart';

/// Results screen — matches web app's results-view.tsx
class ResultsScreen extends ConsumerStatefulWidget {
  final double price;
  final String label;
  final String category;

  const ResultsScreen({
    super.key,
    required this.price,
    required this.label,
    required this.category,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    _autoSave();
  }

  Future<void> _autoSave() async {
    try {
      final profile = ref.read(profileProvider).value;
      if (profile == null) return;

      final calcs = SpendingCalculations.calculate(widget.price, profile);
      final purchase = PurchaseHistory(
        price: widget.price,
        label: widget.label,
        category: widget.category,
        decision: 'undecided',
        timestamp: DateTime.now(),
        timeOfDay: DateTime.now().hour,
        calculations: calcs,
      );

      final service = PurchaseService();
      final authState = ref.read(authStateProvider);
      final isGuest = ref.read(isGuestProvider);

      final user = authState.value;
      if (user != null) {
        await service.savePurchase(user.uid, purchase);
      } else if (isGuest) {
        await service.saveGuestPurchase(purchase);
      }
    } catch (e) {
      debugPrint('ResultsScreen: Error auto-saving: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;
    final profile = ref.watch(profileProvider).value;

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Text('Profile not found', style: theme.textTheme.bodyLarge),
        ),
      );
    }

    final timeMins = SpendingCalculations.timeInMinutes(
      widget.price,
      profile.hourlyWage,
    );
    final timeStr = SpendingCalculations.formatTime(timeMins);
    final contextStr = SpendingCalculations.timeContext(timeMins);
    final calcs = SpendingCalculations.calculate(widget.price, profile);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Label badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ext.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ext.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Price
              Text(
                '€${widget.price.toStringAsFixed(2)}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: ext.accent,
                ),
              ),
              const SizedBox(height: 24),

              // Time cost card — the primary insight
              _InsightCard(
                icon: LucideIcons.clock,
                iconColor: theme.colorScheme.primary,
                title: 'Time Cost',
                value: timeStr,
                description: contextStr,
              ),
              const SizedBox(height: 12),

              // Life equivalences
              _InsightCard(
                icon: LucideIcons.trendingUp,
                iconColor: ext.chart4,
                title: 'Emergency Buffer Impact',
                value: '${calcs.emergencyBufferDays.toStringAsFixed(1)} days',
                description: 'of emergency savings eaten',
              ),
              const SizedBox(height: 12),

              _InsightCard(
                icon: LucideIcons.utensils,
                iconColor: ext.chart3,
                title: 'Grocery Equivalent',
                value: '${calcs.weeksOfGroceries.toStringAsFixed(1)} weeks',
                description: 'of groceries',
              ),
              const SizedBox(height: 12),

              _InsightCard(
                icon: LucideIcons.zap,
                iconColor: ext.accent,
                title: 'Utility Cost',
                value: '${calcs.daysOfUtilities.toStringAsFixed(1)} days',
                description: 'of utilities covered',
              ),

              // Goal impact (if goals set)
              if (profile.emergencyFundGoal != null) ...[
                const SizedBox(height: 12),
                _goalSection(theme, ext, profile),
              ],

              const SizedBox(height: 24),

              // Regret simulator
              _regretSimulator(theme, ext, timeMins),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home/check'),
                      icon: const Icon(LucideIcons.arrowLeft, size: 16),
                      label: const Text('New Check'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/home/insights'),
                      icon: const Icon(LucideIcons.barChart3, size: 16),
                      label: const Text('Insights'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalSection(ThemeData theme, AppColorScheme ext, profile) {
    final percentage = profile.emergencyFundGoal! > 0
        ? ((widget.price / profile.emergencyFundGoal!) * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.target,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Goal Impact', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This costs ${percentage.toStringAsFixed(1)}% of your emergency fund goal',
            style: theme.textTheme.bodySmall?.copyWith(
              color: ext.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _regretSimulator(
    ThemeData theme,
    AppColorScheme ext,
    double timeMins,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ext.accent.withValues(alpha: 0.05),
            ext.accent.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ext.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.brain, size: 18, color: ext.accent),
              const SizedBox(width: 8),
              Text('Regret Simulator', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Would you trade ${SpendingCalculations.formatTime(timeMins)} of your life for "${widget.label}"?',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'If this purchase were free, would you still want it?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: ext.mutedForeground,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String description;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelMedium),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
