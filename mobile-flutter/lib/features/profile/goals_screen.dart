import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Goals screen — matches web app's goals-modal.tsx
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _emergencyController = TextEditingController();
  final _freedomController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      if (profile.emergencyFundGoal != null) {
        _emergencyController.text = '${profile.emergencyFundGoal!.round()}';
      }
      if (profile.freedomGoal != null) {
        _freedomController.text = '${profile.freedomGoal!.round()}';
      }
    }
  }

  @override
  void dispose() {
    _emergencyController.dispose();
    _freedomController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    final emergency = double.tryParse(_emergencyController.text);
    final freedom = double.tryParse(_freedomController.text);

    final updated = profile.copyWith(
      emergencyFundGoal: emergency,
      freedomGoal: freedom,
      clearEmergencyFund: _emergencyController.text.isEmpty,
      clearFreedomGoal: _freedomController.text.isEmpty,
    );

    await ref.read(profileProvider.notifier).saveProfile(updated);

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
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
        title: const Text('Financial Goals'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title
            Text(
              'What are you building toward?',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Setting financial targets helps MindSpend show the true impact of purchases on your goals.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ext.mutedForeground,
              ),
            ),
            const SizedBox(height: 28),

            // Emergency fund
            Row(
              children: [
                Icon(
                  LucideIcons.shield,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Emergency Fund', style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emergencyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                prefixText: '€ ',
                hintText: '10000',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '3–6 months of expenses is typical',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ext.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),

            // Freedom goal
            Row(
              children: [
                Icon(LucideIcons.flame, size: 16, color: ext.accent),
                const SizedBox(width: 8),
                Text('Future Freedom', style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _freedomController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                prefixText: '€ ',
                hintText: '100000',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your total financial independence target',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ext.mutedForeground,
              ),
            ),
            const SizedBox(height: 32),

            // Save
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save Goals'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
