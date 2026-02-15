import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';

/// Settings screen — matches web app's settings-modal.tsx
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _incomeController = TextEditingController();
  final _workingDaysController = TextEditingController();
  final _expensesController = TextEditingController();
  String _inputType = 'monthly';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  void _loadCurrent() {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    _workingDaysController.text = '${profile.workingDaysPerYear}';
    _expensesController.text = '${profile.monthlyExpenses.round()}';
    // Back-calculate monthly income from hourly wage
    final hoursPerYear = profile.workingDaysPerYear * 8;
    final annualIncome = profile.hourlyWage * hoursPerYear;
    final monthlyIncome = annualIncome / 12;
    _incomeController.text = '${monthlyIncome.round()}';
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _workingDaysController.dispose();
    _expensesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final inputValue = double.tryParse(_incomeController.text) ?? 0;
    final workingDays = int.tryParse(_workingDaysController.text) ?? 220;
    final expenses = double.tryParse(_expensesController.text) ?? 0;

    double hourly;
    if (_inputType == 'hourly') {
      hourly = inputValue;
    } else {
      final hoursPerYear = workingDays * 8;
      final annualIncome = inputValue * 12;
      hourly = annualIncome / hoursPerYear;
    }

    final currentProfile = ref.read(profileProvider).value;
    final profile = UserProfile(
      hourlyWage: (hourly * 100).roundToDouble() / 100,
      workingDaysPerYear: workingDays,
      monthlyExpenses: expenses.roundToDouble(),
      emergencyFundGoal: currentProfile?.emergencyFundGoal,
      freedomGoal: currentProfile?.freedomGoal,
    );

    await ref.read(profileProvider.notifier).saveProfile(profile);

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will clear your profile and purchase history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.destructive,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final isGuest = ref.read(isGuestProvider);
    if (isGuest) {
      await ref.read(authServiceProvider).clearGuestData();
    }
    ref.read(profileProvider.notifier).clear();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ext.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildToggle('monthly', 'Monthly Income', theme),
                  _buildToggle('hourly', 'Hourly Wage', theme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Income
            Text(
              _inputType == 'monthly' ? 'Monthly Income' : 'Hourly Wage',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: '€ ',
                hintText: _inputType == 'monthly' ? '3000' : '25',
              ),
            ),
            const SizedBox(height: 20),

            // Working days
            Text('Days worked per year', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _workingDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '220'),
            ),
            const SizedBox(height: 20),

            // Monthly expenses
            Text('Monthly Expenses', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _expensesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                prefixText: '€ ',
                hintText: '2000',
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save Changes'),
              ),
            ),
            const SizedBox(height: 32),

            // Danger zone
            Divider(color: ext.border),
            const SizedBox(height: 20),
            Text(
              'DANGER ZONE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: ext.destructive,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetData,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ext.destructive,
                  side: BorderSide(
                    color: ext.destructive.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text('Reset All Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String type, String label, ThemeData theme) {
    final isActive = _inputType == type;
    final ext = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _inputType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? theme.scaffoldBackgroundColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? theme.textTheme.bodyLarge?.color
                  : ext.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
