import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';

/// Profile screen — matches web app's profile-page.tsx
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _deleting = false;
  bool _updatingAvatar = false;

  static const List<_AvatarPreset> _avatarOptions = [
    _AvatarPreset('bolt', 'Bolt', LucideIcons.zap, Color(0xFFF4B740)),
    _AvatarPreset('leaf', 'Leaf', LucideIcons.leaf, Color(0xFF34D399)),
    _AvatarPreset('moon', 'Moon', LucideIcons.moon, Color(0xFF7EA8FF)),
    _AvatarPreset('heart', 'Heart', LucideIcons.heart, Color(0xFFFF6B8A)),
    _AvatarPreset('star', 'Star', LucideIcons.star, Color(0xFFB08BFF)),
    _AvatarPreset('sparkles', 'Sparkles', LucideIcons.sparkles, Color(0xFF4DD0E1)),
  ];

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

  Future<void> _pickProfilePhoto(UserProfile? profile) async {
    if (profile == null || _updatingAvatar) return;
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      await _saveAvatar(
        profile.copyWith(
          avatarImageBase64: base64Encode(bytes),
          clearAvatarPreset: true,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image. Try again.')),
      );
    }
  }

  Future<void> _chooseAvatar(UserProfile? profile) async {
    if (profile == null || _updatingAvatar) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final ext = ctx.colors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose avatar', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _avatarOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, i) {
                    final preset = _avatarOptions[i];
                    final isSelected = profile.avatarPreset == preset.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx, preset.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: preset.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? preset.color : ext.border,
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(preset.icon, size: 18, color: preset.color),
                            const SizedBox(height: 4),
                            Text(
                              preset.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? preset.color
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    await _saveAvatar(
      profile.copyWith(avatarPreset: selected, clearAvatarImage: true),
    );
  }

  Future<void> _removeUploadedPhoto(UserProfile? profile) async {
    if (profile == null || _updatingAvatar) return;
    await _saveAvatar(
      profile.copyWith(clearAvatarImage: true, clearAvatarPreset: true),
    );
  }

  Future<void> _openAvatarEditor(UserProfile? profile) async {
    if (profile == null || _updatingAvatar) return;
    final hasUploadedPhoto = profile.avatarImageBase64?.isNotEmpty ?? false;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    hasUploadedPhoto ? LucideIcons.refreshCw : LucideIcons.image,
                  ),
                  title: Text(hasUploadedPhoto ? 'Reupload photo' : 'Upload photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickProfilePhoto(profile);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.userCircle2),
                  title: const Text('Choose avatar'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _chooseAvatar(profile);
                  },
                ),
                if (hasUploadedPhoto)
                  ListTile(
                    leading: Icon(
                      LucideIcons.trash2,
                      color: Theme.of(context).extension<AppColorScheme>()!.destructive,
                    ),
                    title: Text(
                      'Delete photo',
                      style: TextStyle(
                        color: Theme.of(context)
                            .extension<AppColorScheme>()!
                            .destructive,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeUploadedPhoto(profile);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAvatar(UserProfile updated) async {
    setState(() => _updatingAvatar = true);
    try {
      await ref.read(profileProvider.notifier).saveProfile(updated);
    } finally {
      if (mounted) setState(() => _updatingAvatar = false);
    }
  }

  Widget _buildAvatar(User? user, bool isGuest, UserProfile? profile) {
    final hasPhoto = (profile?.avatarImageBase64?.isNotEmpty ?? false);
    final preset = _findAvatarPreset(profile?.avatarPreset);

    Widget inner;
    if (hasPhoto) {
      try {
        final bytes = base64Decode(profile!.avatarImageBase64!);
        inner = ClipOval(
          child: Image.memory(
            bytes,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initialsAvatar(user, isGuest),
          ),
        );
      } catch (_) {
        inner = _initialsAvatar(user, isGuest);
      }
    } else if (preset != null) {
      inner = Container(
        decoration: BoxDecoration(
          color: preset.color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(preset.icon, color: preset.color, size: 28),
      );
    } else {
      inner = _initialsAvatar(user, isGuest);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          child: inner,
        ),
        if (_updatingAvatar)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (!_updatingAvatar)
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openAvatarEditor(profile),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.card, width: 1.8),
                  ),
                  child: const Icon(
                    LucideIcons.pencil,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  _AvatarPreset? _findAvatarPreset(String? id) {
    for (final preset in _avatarOptions) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  Widget _initialsAvatar(User? user, bool isGuest) {
    final theme = Theme.of(context);
    final ext = context.colors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary, ext.accent]),
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
    );
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
                  _buildAvatar(user, isGuest, profile),
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

class _AvatarPreset {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const _AvatarPreset(this.id, this.label, this.icon, this.color);
}
