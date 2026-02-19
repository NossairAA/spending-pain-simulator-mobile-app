import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/purchase_history.dart';
import '../../services/purchase_service.dart';
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

  Future<void> _loadHistory({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _loading = true);
    }

    List<PurchaseHistory> loadedHistory = [];
    try {
      final service = PurchaseService();
      final authState = ref.read(authStateProvider);
      final isGuest = ref.read(isGuestProvider);

      // If auth state is still loading, wait briefly for it
      final user = authState.when(
        data: (u) => u,
        loading: () => null,
        error: (_, _) => null,
      );

      if (user != null) {
        loadedHistory = await service.getPurchaseHistory(user.uid);
      } else if (isGuest) {
        loadedHistory = await service.getGuestPurchaseHistory();
      }
    } catch (e) {
      // If Firestore fails, show empty state rather than infinite loading
      debugPrint('InsightsScreen: Error loading history: $e');
      loadedHistory = [];
    }
    if (!mounted) return;
    setState(() {
      _history = loadedHistory;
      if (showLoader) _loading = false;
    });
  }

  Future<void> _updateDecision(String id, String decision) async {
    final previousHistory = _history;
    setState(() {
      _history = _history
          .map((item) => item.id == id ? item.copyWith(decision: decision) : item)
          .toList();
    });

    try {
      final service = PurchaseService();
      final user = ref.read(authStateProvider).value;
      final isGuest = ref.read(isGuestProvider);

      if (user != null) {
        await service.updateDecision(user.uid, id, decision);
      } else if (isGuest) {
        await service.updateGuestDecision(id, decision);
      }
      _loadHistory(showLoader: false);
    } catch (e) {
      debugPrint('InsightsScreen: Error updating decision: $e');
      if (mounted) {
        setState(() => _history = previousHistory);
      }
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
    final totalLifeSavedMinutes = _history
        .where((p) => p.decision == 'skipped')
        .fold<double>(0, (sum, p) => sum + p.calculations.timeInMinutes);
    final totalLifeSaved = SpendingCalculations.formatTime(totalLifeSavedMinutes);

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
                  if (totalSaved > 0 || totalLifeSavedMinutes > 0)
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
                          Expanded(
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
                          Container(
                            width: 1,
                            height: 40,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.clock3,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Life Saved',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                    Text(
                                      totalLifeSaved,
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

class _PurchaseCard extends StatefulWidget {
  final PurchaseHistory purchase;
  final Function(String id, String decision) onDecision;
  final Function(String id) onDelete;

  const _PurchaseCard({
    required this.purchase,
    required this.onDecision,
    required this.onDelete,
  });

  @override
  State<_PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends State<_PurchaseCard> {
  late bool _isEditing;
  late String _decision;

  @override
  void initState() {
    super.initState();
    _decision = widget.purchase.decision;
    _isEditing = _decision == 'undecided';
  }

  @override
  void didUpdateWidget(covariant _PurchaseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.purchase.id != widget.purchase.id) {
      _decision = widget.purchase.decision;
      _isEditing = _decision == 'undecided';
      return;
    }

    if (oldWidget.purchase.decision != widget.purchase.decision) {
      _decision = widget.purchase.decision;
      if (_decision == 'undecided') {
        _isEditing = true;
      }
    }
  }

  String _decisionLabel(String decision) {
    switch (decision) {
      case 'bought':
        return 'Bought';
      case 'skipped':
        return 'Skipped';
      default:
        return 'No decision yet';
    }
  }

  Color _decisionColor(ThemeData theme, AppColorScheme ext, String decision) {
    if (decision == 'bought') return ext.accent;
    if (decision == 'skipped') return theme.colorScheme.primary;
    return ext.mutedForeground;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;
    final purchase = widget.purchase;
    final timeStr = SpendingCalculations.formatTime(
      purchase.calculations.timeInMinutes,
    );
    final ago = SpendingCalculations.getTimeAgo(purchase.timestamp);
    final decisionColor = _decisionColor(theme, ext, _decision);

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
                onPressed: purchase.id == null
                    ? null
                    : () => widget.onDelete(purchase.id!),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetTween = Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetTween.animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isEditing
                  ? _DecisionToggle(
                      key: const ValueKey('toggle'),
                      decision: _decision,
                      skipColor: theme.colorScheme.primary,
                      buyColor: ext.accent,
                      onSkip: () {
                        if (_decision == 'skipped') {
                          setState(() => _isEditing = false);
                          return;
                        }

                        setState(() {
                          _decision = 'skipped';
                          _isEditing = false;
                        });
                        if (purchase.id != null) {
                          widget.onDecision(purchase.id!, 'skipped');
                        }
                      },
                      onBuy: () {
                        if (_decision == 'bought') {
                          setState(() => _isEditing = false);
                          return;
                        }

                        setState(() {
                          _decision = 'bought';
                          _isEditing = false;
                        });
                        if (purchase.id != null) {
                          widget.onDecision(purchase.id!, 'bought');
                        }
                      },
                    )
                  : Row(
                      key: const ValueKey('decision'),
                      children: [
                        Expanded(
                          child: _DecisionBadge(
                            label: _decisionLabel(_decision),
                            color: decisionColor,
                            icon: _decision == 'bought'
                                ? LucideIcons.x
                                : LucideIcons.check,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.pencil,
                            size: 16,
                            color: ext.mutedForeground,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isEditing = true);
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionToggle extends StatelessWidget {
  final String decision;
  final Color skipColor;
  final Color buyColor;
  final VoidCallback onSkip;
  final VoidCallback onBuy;

  const _DecisionToggle({
    super.key,
    required this.decision,
    required this.skipColor,
    required this.buyColor,
    required this.onSkip,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;

    Widget option({
      required String label,
      required bool selected,
      required Color color,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(LucideIcons.check, size: 13, color: color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : ext.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: [
          option(
            label: 'Skipped',
            selected: decision == 'skipped',
            color: skipColor,
            onTap: onSkip,
          ),
          const SizedBox(width: 4),
          option(
            label: 'Bought',
            selected: decision == 'bought',
            color: buyColor,
            onTap: onBuy,
          ),
        ],
      ),
    );
  }
}

class _DecisionBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _DecisionBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
