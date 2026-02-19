import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/auth_provider.dart';
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
  String _message = '';

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
    final authService = ref.read(authServiceProvider);

    if (value) {
      final saved = await authService.loadSavedCredentials();
      if (!saved.rememberPassword ||
          saved.email.isEmpty ||
          saved.password.isEmpty) {
        if (mounted) {
          setState(() {
            _updating = false;
            _message =
                'Enable Remember password in sign-in first so biometrics can restore your account.';
          });
        }
        return;
      }

      final verified = await service.authenticateToEnable();
      if (!verified) {
        if (mounted) {
          setState(() {
            _updating = false;
            _message = 'Biometric verification failed. Try again.';
          });
        }
        return;
      }
    }

    await service.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() {
      _enabled = value;
      _updating = false;
      _message = value
          ? 'Biometric sign-in is now enabled.'
          : 'Biometric sign-in is now disabled.';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protect your account with Face ID or fingerprint. On cold launch, biometric verification can restore your signed-out session using remembered credentials.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ext.mutedForeground,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
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
                                  Text(
                                    'Biometric sign-in',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _available
                                        ? (_enabled ? 'Enabled' : 'Disabled')
                                        : 'Unavailable on this device',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _available
                                          ? (_enabled
                                                ? theme.colorScheme.primary
                                                : ext.mutedForeground)
                                          : ext.warning,
                                      fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 12),
                        Text(
                          _available
                              ? 'Requires verification when enabling. Keep Remember password enabled so biometric restore can sign you in securely.'
                              : 'Set up Face ID/fingerprint on your device and reopen this screen.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ext.mutedForeground,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
