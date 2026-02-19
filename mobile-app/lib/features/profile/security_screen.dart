import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/biometric_provider.dart';
import '../../theme/app_theme.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _loading = true;
  bool _available = false;
  bool _enabled = false;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final service = ref.read(biometricAuthServiceProvider);
    final available = await service.isBiometricAvailable();
    final enabled = available ? await service.isBiometricEnabled() : false;
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_updating || !_available) return;

    setState(() => _updating = true);
    final service = ref.read(biometricAuthServiceProvider);

    if (value) {
      final verified = await service.authenticateToEnable();
      if (!verified) {
        if (mounted) {
          setState(() => _updating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric verification failed. Try again.'),
            ),
          );
        }
        return;
      }
    }

    await service.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() {
      _enabled = value;
      _updating = false;
    });
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
        title: const Text('Security'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ext.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ext.border),
          ),
          child: _loading
              ? const SizedBox(
                  height: 56,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.scanFace,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Biometric lock', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 3),
                          Text(
                            _available
                                ? 'Use Face ID on iOS or fingerprint on Android to unlock the app.'
                                : 'Biometrics are unavailable on this device.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ext.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enabled,
                      onChanged: (!_available || _updating)
                          ? null
                          : _toggleBiometric,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
