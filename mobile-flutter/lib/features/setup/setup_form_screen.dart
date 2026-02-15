import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';

/// Setup form screen — matches web app's setup-form.tsx
class SetupFormScreen extends ConsumerStatefulWidget {
  const SetupFormScreen({super.key});

  @override
  ConsumerState<SetupFormScreen> createState() => _SetupFormScreenState();
}

class _SetupFormScreenState extends ConsumerState<SetupFormScreen> {
  String _inputType = 'monthly'; // 'monthly' | 'hourly'
  final _inputController = TextEditingController();
  final _workingDaysController = TextEditingController(text: '220');
  final _expensesController = TextEditingController();
  bool _showAdvanced = false;

  @override
  void dispose() {
    _inputController.dispose();
    _workingDaysController.dispose();
    _expensesController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _inputController.text.isNotEmpty;

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;

    double hourly = 0;
    double expenses = 0;

    final inputValue = double.tryParse(_inputController.text) ?? 0;
    final workingDays = int.tryParse(_workingDaysController.text) ?? 220;

    if (_inputType == 'hourly') {
      hourly = inputValue;
    } else {
      final hoursPerYear = workingDays * 8;
      final annualIncome = inputValue * 12;
      hourly = annualIncome / hoursPerYear;
    }

    if (_expensesController.text.isNotEmpty) {
      expenses = double.tryParse(_expensesController.text) ?? 0;
    } else {
      if (_inputType == 'monthly') {
        expenses = inputValue * 0.8;
      } else {
        expenses = (inputValue * 8 * 21.6) * 0.8;
      }
    }

    final profile = UserProfile(
      hourlyWage: (hourly * 100).roundToDouble() / 100,
      workingDaysPerYear: workingDays,
      monthlyExpenses: expenses.roundToDouble(),
    );

    await ref.read(profileProvider.notifier).saveProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
              const SizedBox(height: 32),

              // Title
              Text(
                "Let's get personal",
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'We need a baseline to calculate your "Spending Pain". Only 2 numbers required.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ext.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(height: 32),

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
              const SizedBox(height: 12),

              // Income input
              TextField(
                controller: _inputController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: false,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: _inputType == 'monthly' ? '€ ' : '\$ ',
                  prefixStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ext.mutedForeground,
                  ),
                  hintText: _inputType == 'monthly' ? '3000' : '25',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _inputType == 'monthly'
                        ? 'Net income after tax (take-home pay)'
                        : 'Net hourly wage after tax',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ext.mutedForeground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Working days
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Days worked per year',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _workingDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '220'),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Standard full-time is ~220 days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ext.mutedForeground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Advanced toggle
              GestureDetector(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Row(
                  children: [
                    Text(
                      _showAdvanced
                          ? 'Hide advanced settings'
                          : 'Improve accuracy (optional)',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.arrowRight,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),

              if (_showAdvanced) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ext.muted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ext.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY EXPENSES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                        ),
                      ),
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
                      const SizedBox(height: 4),
                      Text(
                        'Leave empty to estimate based on income',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ext.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  child: Text(
                    'Start Spending Pain',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String type, String label, ThemeData theme) {
    final isActive = _inputType == type;
    final ext = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _inputType = type;
          _inputController.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? theme.scaffoldBackgroundColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
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
