import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

/// Price input screen — matches web app's price-input.tsx
class PriceInputScreen extends StatefulWidget {
  const PriceInputScreen({super.key});

  @override
  State<PriceInputScreen> createState() => _PriceInputScreenState();
}

class _PriceInputScreenState extends State<PriceInputScreen> {
  final _priceController = TextEditingController();
  final _labelController = TextEditingController();
  String _category = 'other';

  static const _categories = [
    ('food', 'Food', '🍔'),
    ('tech', 'Tech', '📱'),
    ('clothes', 'Clothes', '👕'),
    ('fun', 'Fun', '🎉'),
    ('transport', 'Travel', '🚗'),
    ('subscription', 'Sub', '📺'),
    ('other', 'Other', '📦'),
  ];

  @override
  void dispose() {
    _priceController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final price = double.tryParse(_priceController.text) ?? 0;
    if (price <= 0) return;

    final label = _labelController.text.isEmpty
        ? 'this purchase'
        : _labelController.text;

    context.go(
      '/cooloff',
      extra: {'price': price, 'label': label, 'category': _category},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;
    final price = double.tryParse(_priceController.text) ?? 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Title
              Text(
                'What are you about\nto spend?',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the amount. We will show you what it really costs.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ext.mutedForeground,
                ),
              ),
              const SizedBox(height: 32),

              // Price input
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: '€ ',
                  prefixStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                  hintText: '0.00',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Label input
              TextField(
                controller: _labelController,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 16,
                    color: ext.mutedForeground,
                  ),
                  hintText: 'What is it? (e.g., new shoes, dinner out)',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: ext.mutedForeground.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Categories
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _categories.map((cat) {
                  final isSelected = _category == cat.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : ext.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : ext.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.$3, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            cat.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : ext.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: price > 0 ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  child: Text(
                    'Show me the truth',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
