import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../services/auth_service.dart';

/// Auth screen — full-screen version of web's auth-modal.tsx
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignIn = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';
  bool _loading = false;
  bool _loadingPrefs = true;
  bool _verificationSent = false;
  bool _rememberPassword = false;
  bool _biometricSignInEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadBiometricOption();
  }

  Future<void> _loadBiometricOption() async {
    final biometricService = ref.read(biometricAuthServiceProvider);
    final authService = ref.read(authServiceProvider);

    final available = await biometricService.isBiometricAvailable();
    final enabled = available ? await biometricService.isBiometricEnabled() : false;
    final saved = await authService.loadSavedCredentials();

    if (!mounted) return;
    setState(() {
      _biometricSignInEnabled =
          enabled && saved.rememberPassword && saved.email.isNotEmpty && saved.password.isNotEmpty;
    });
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await ref.read(authServiceProvider).loadSavedCredentials();
    if (!mounted) return;
    setState(() {
      _rememberPassword = prefs.rememberPassword;
      _emailController.text = prefs.email;
      if (prefs.rememberPassword) {
        _passwordController.text = prefs.password;
      }
      _loadingPrefs = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final service = ref.read(authServiceProvider);
      await service.signInWithGoogle();
      ref.read(profileProvider.notifier).reload();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } catch (e) {
      setState(() => _error = 'Failed to sign in with Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleBiometricSignIn() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final biometricService = ref.read(biometricAuthServiceProvider);
      final authService = ref.read(authServiceProvider);

      final verified = await biometricService.authenticateToUnlock();
      if (!verified) {
        setState(() => _error = 'Biometric verification failed. Try again.');
        return;
      }

      final restored = await authService.signInWithSavedCredentials();
      if (!restored) {
        setState(() {
          _error =
              'Biometric sign-in is enabled, but saved credentials were not found. Please sign in with email/password once.';
        });
        return;
      }

      ref.read(profileProvider.notifier).reload();
    } catch (_) {
      setState(() => _error = 'Biometric sign-in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
      _verificationSent = false;
    });

    try {
      final service = ref.read(authServiceProvider);
      if (_isSignIn) {
        await service.signInWithEmail(email, password);
        TextInput.finishAutofillContext(shouldSave: true);
        await service.saveCredentialsPreference(
          email: email,
          password: password,
          rememberPassword: _rememberPassword,
        );
        ref.read(profileProvider.notifier).reload();
        await _loadBiometricOption();
      } else {
        await service.signUpWithEmail(email, password);
        TextInput.finishAutofillContext(shouldSave: true);
        await service.saveCredentialsPreference(
          email: email,
          password: password,
          rememberPassword: _rememberPassword,
        );
        setState(() => _verificationSent = true);
        await _loadBiometricOption();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } catch (e) {
      setState(() => _error = 'Failed to ${_isSignIn ? "sign in" : "sign up"}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleGuestMode() {
    ref.read(isGuestProvider.notifier).set(true);
    ref.read(profileProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;

    if (_loadingPrefs) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_verificationSent) {
      return _buildVerificationSent(theme, ext);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Listener(
        onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Text(
                  _isSignIn ? 'Welcome Back' : 'Create Account',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _isSignIn
                      ? 'Sign in to sync your data'
                      : 'Sign up to save your profile',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ext.mutedForeground,
                  ),
                ),
                const SizedBox(height: 24),

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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ext.destructive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Google Sign-In
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _handleGoogleSignIn,
                    icon: const Icon(LucideIcons.chrome, size: 20),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_isSignIn && _biometricSignInEnabled) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _handleBiometricSignIn,
                      icon: const Icon(LucideIcons.scanFace, size: 20),
                      label: const Text('Continue with Biometrics'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: ext.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ext.mutedForeground,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: ext.border)),
                  ],
                ),
                const SizedBox(height: 24),

                // Email field
                Row(
                  children: [
                    Icon(
                      LucideIcons.mail,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Email', style: theme.textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: _isSignIn
                      ? const [AutofillHints.username, AutofillHints.email]
                      : const [AutofillHints.newUsername, AutofillHints.email],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                Row(
                  children: [
                    Icon(
                      LucideIcons.lock,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Password', style: theme.textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleEmailAuth(),
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: _isSignIn
                      ? const [AutofillHints.password]
                      : const [AutofillHints.newPassword],
                  decoration: const InputDecoration(hintText: '••••••••'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberPassword,
                      onChanged: _loading
                          ? null
                          : (value) {
                              setState(() => _rememberPassword = value ?? false);
                            },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Remember password',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ext.mutedForeground,
                      ),
                    ),
                  ],
                ),
                if (!_isSignIn) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Minimum 6 characters',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ext.mutedForeground,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleEmailAuth,
                    child: Text(_isSignIn ? 'Sign In' : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle mode
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isSignIn = !_isSignIn;
                      _error = '';
                    }),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ext.mutedForeground,
                        ),
                        children: [
                          TextSpan(
                            text: _isSignIn
                                ? "Don't have an account? "
                                : 'Already have an account? ',
                          ),
                          TextSpan(
                            text: _isSignIn ? 'Sign up' : 'Sign in',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Guest mode
                Divider(color: ext.border),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleGuestMode,
                    child: Column(
                      children: [
                        const Text('Continue as Guest'),
                        const SizedBox(height: 2),
                        Text(
                          'Data stays on this device only',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ext.mutedForeground.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Privacy note
                Text(
                  'Your data is private and secure. We never track or share your information.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.mutedForeground.withValues(alpha: 0.6),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSent(ThemeData theme, AppColorScheme ext) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.checkCircle,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text('Check Your Email', style: theme.textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                'Verification email sent!',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ext.mutedForeground,
                  ),
                  children: [
                    const TextSpan(text: "We've sent a verification link to "),
                    TextSpan(
                      text: _emailController.text,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your email and click the link to verify your account, then sign in.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ext.mutedForeground,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() {
                  _verificationSent = false;
                  _isSignIn = true;
                  _passwordController.clear();
                }),
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
