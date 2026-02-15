import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Profile screen — matches web app's profile-page.tsx
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _deleting = false;

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    ref.read(isGuestProvider.notifier).set(false);
    ref.read(profileProvider.notifier).clear();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all your data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(
                context,
              ).extension<AppColorScheme>()!.destructive,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authServiceProvider).deleteAccount();
      ref.read(profileProvider.notifier).clear();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to delete account')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;
    final authState = ref.watch(authStateProvider);
    final isGuest = ref.watch(isGuestProvider);
    final user = authState.value;
    final profile = ref.watch(profileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 20),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar & info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ext.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ext.border),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, ext.accent],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(user, isGuest),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    isGuest
                        ? 'Guest User'
                        : (user?.displayName ?? user?.email ?? 'User'),
                    style: theme.textTheme.titleLarge,
                  ),

                  // Email
                  if (!isGuest && user?.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ext.mutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isGuest
                          ? ext.warning.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isGuest ? 'Guest Mode' : _getProviderLabel(user),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isGuest
                            ? ext.warning
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            if (profile != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ext.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ext.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Setup', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Hourly wage',
                      value: '€${profile.hourlyWage.toStringAsFixed(2)}/hr',
                    ),
                    _StatRow(
                      label: 'Working days / year',
                      value: '${profile.workingDaysPerYear}',
                    ),
                    _StatRow(
                      label: 'Monthly expenses',
                      value: '€${profile.monthlyExpenses.toStringAsFixed(0)}',
                    ),
                    if (profile.emergencyFundGoal != null)
                      _StatRow(
                        label: 'Emergency fund goal',
                        value:
                            '€${profile.emergencyFundGoal!.toStringAsFixed(0)}',
                      ),
                    if (profile.freedomGoal != null)
                      _StatRow(
                        label: 'Freedom goal',
                        value: '€${profile.freedomGoal!.toStringAsFixed(0)}',
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Quick actions
            _ActionTile(
              icon: LucideIcons.target,
              label: 'Financial Goals',
              onTap: () => context.push('/goals'),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: LucideIcons.settings,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 24),

            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(LucideIcons.logOut, size: 16),
                label: Text(isGuest ? 'Exit Guest Mode' : 'Sign Out'),
              ),
            ),

            // Delete account
            if (!isGuest) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _deleting ? null : _deleteAccount,
                  style: TextButton.styleFrom(foregroundColor: ext.destructive),
                  child: Text(_deleting ? 'Deleting...' : 'Delete Account'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getInitials(User? user, bool isGuest) {
    if (isGuest) return 'G';
    final name = user?.displayName ?? user?.email ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getProviderLabel(User? user) {
    if (user == null) return '';
    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    return isGoogle ? 'Google Account' : 'Email Account';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: ext.mutedForeground),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ext.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ext.mutedForeground),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: ext.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
