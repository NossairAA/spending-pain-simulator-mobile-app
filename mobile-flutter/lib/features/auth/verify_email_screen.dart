import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Verify email screen — matches web's verify-email-screen.tsx
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _loading = false;
  bool _sent = false;
  String _error = '';

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await ref.read(authServiceProvider).resendVerificationEmail();
      setState(() => _sent = true);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _sent = false);
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Failed to send verification email');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ext.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.mail, color: ext.warning, size: 32),
                ),
                const SizedBox(height: 24),

                // Title
                Text('Verify Your Email', style: theme.textTheme.displaySmall),
                const SizedBox(height: 8),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ext.mutedForeground,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a verification link to '),
                      TextSpan(
                        text: user?.email ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ext.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ext.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Please check your email and click the verification link to continue. After verifying, refresh this page or sign in again.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error
                if (_error.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ext.destructive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ext.destructive.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _error,
                      style: TextStyle(color: ext.destructive, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Success
                if (_sent) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '✓ Verification email sent! Check your inbox.',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Resend button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _resend,
                    icon: Icon(
                      LucideIcons.refreshCw,
                      size: 16,
                      color: _loading ? null : theme.colorScheme.onPrimary,
                    ),
                    label: Text(
                      _loading ? 'Sending...' : 'Resend Verification Email',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign out
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(LucideIcons.logOut, size: 16),
                    label: const Text('Sign Out'),
                  ),
                ),
                const SizedBox(height: 24),

                // Help text
                Text(
                  "Can't find the email? Check your spam folder or try a different email address.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
