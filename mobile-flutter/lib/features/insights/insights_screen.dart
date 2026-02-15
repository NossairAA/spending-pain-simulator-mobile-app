import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/purchase_history.dart';
import '../../api/purchase_service.dart';
import '../../utils/calculations.dart';

/// Insights screen — matches web app's insights-page.tsx
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  List<PurchaseHistory> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final service = PurchaseService();
      final authState = ref.read(authStateProvider);
      final isGuest = ref.read(isGuestProvider);

      // If auth state is still loading, wait briefly for it
      final user = authState.when(
        data: (u) => u,
        loading: () => null,
        error: (_, __) => null,
      );

      if (user != null) {
        _history = await service.getPurchaseHistory(user.uid);
      } else if (isGuest) {
        _history = await service.getGuestPurchaseHistory();
      } else {
        _history = [];
      }
    } catch (e) {
      // If Firestore fails, show empty state rather than infinite loading
      debugPrint('InsightsScreen: Error loading history: $e');
      _history = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateDecision(String id, String decision) async {
    try {
      final service = PurchaseService();
      final user = ref.read(authStateProvider).value;
      final isGuest = ref.read(isGuestProvider);

      if (user != null) {
        await service.updateDecision(user.uid, id, decision);
      } else if (isGuest) {
        await service.updateGuestDecision(id, decision);
      }
      _loadHistory();
    } catch (e) {
      debugPrint('InsightsScreen: Error updating decision: $e');
    }
  }

  Future<void> _deletePurchase(String id) async {
    try {
      final service = PurchaseService();
      final user = ref.read(authStateProvider).value;
      final isGuest = ref.read(isGuestProvider);

      if (user != null) {
        await service.deletePurchase(user.uid, id);
      } else if (isGuest) {
        await service.deleteGuestPurchase(id);
      }
      _loadHistory();
    } catch (e) {
      debugPrint('InsightsScreen: Error deleting purchase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Insights', style: theme.textTheme.headlineMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Stats
    final total = _history.length;
    final skipped = _history.where((p) => p.decision == 'skipped').length;
    final bought = _history.where((p) => p.decision == 'bought').length;
    final totalSaved = _history
        .where((p) => p.decision == 'skipped')
        .fold<double>(0, (sum, p) => sum + p.price);

    return Scaffold(
      appBar: AppBar(
        title: Text('Insights', style: theme.textTheme.headlineMedium),
      ),
      body: _history.isEmpty
          ? _buildEmpty(theme, ext)
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatCard(
                        icon: LucideIcons.eye,
                        label: 'Checks',
                        value: '$total',
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: LucideIcons.skipForward,
                        label: 'Skipped',
                        value: '$skipped',
                        color: ext.chart3,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: LucideIcons.shoppingBag,
                        label: 'Bought',
                        value: '$bought',
                        color: ext.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Saved amount
                  if (totalSaved > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                            theme.colorScheme.primary.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.piggyBank,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Money Saved',
                                style: theme.textTheme.labelMedium,
                              ),
                              Text(
                                '€${totalSaved.toStringAsFixed(2)}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Recent activity
                  Text('Recent Activity', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),

                  ..._history.map(
                    (purchase) => _PurchaseCard(
                      purchase: purchase,
                      onDecision: _updateDecision,
                      onDelete: _deletePurchase,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty(ThemeData theme, AppColorScheme ext) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.barChart3,
              size: 48,
              color: ext.mutedForeground.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No purchase checks yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Start by checking a purchase to see your insights here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ext.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ext.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: ext.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final PurchaseHistory purchase;
  final Function(String id, String decision) onDecision;
  final Function(String id) onDelete;

  const _PurchaseCard({
    required this.purchase,
    required this.onDecision,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;
    final timeStr = SpendingCalculations.formatTime(
      purchase.calculations.timeInMinutes,
    );
    final ago = SpendingCalculations.getTimeAgo(purchase.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.label,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '€${purchase.price.toStringAsFixed(2)} · $timeStr · $ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: ext.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: ext.mutedForeground,
                ),
                onPressed: () => onDelete(purchase.id!),
              ),
            ],
          ),
          if (purchase.decision == 'undecided') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "Did you buy it? ",
                  style: TextStyle(fontSize: 12, color: ext.mutedForeground),
                ),
                const Spacer(),
                _DecisionBtn(
                  label: 'Skipped',
                  color: theme.colorScheme.primary,
                  onTap: () => onDecision(purchase.id!, 'skipped'),
                ),
                const SizedBox(width: 8),
                _DecisionBtn(
                  label: 'Bought',
                  color: ext.accent,
                  onTap: () => onDecision(purchase.id!, 'bought'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: purchase.decision == 'skipped'
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : ext.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                purchase.decision == 'skipped' ? '✓ Skipped' : '✗ Bought',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: purchase.decision == 'skipped'
                      ? theme.colorScheme.primary
                      : ext.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DecisionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DecisionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
