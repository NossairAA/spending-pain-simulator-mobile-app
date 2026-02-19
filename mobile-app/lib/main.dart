import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/router.dart';
import 'providers/biometric_provider.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AppBootstrap()));
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LaunchLoadingScreen();
        }
        return const _BiometricGate(child: MindSpendApp());
      },
    );
  }
}

class _BiometricGate extends ConsumerStatefulWidget {
  final Widget child;

  const _BiometricGate({required this.child});

  @override
  ConsumerState<_BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<_BiometricGate> {
  bool _checking = true;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final service = ref.read(biometricAuthServiceProvider);
    final enabled = await service.isBiometricEnabled();
    final available = await service.isBiometricAvailable();

    if (enabled && !available) {
      await service.setBiometricEnabled(false);
    }

    if (!enabled || !available) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _unlocked = true;
      });
      return;
    }

    final verified = await service.authenticateToUnlock();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _unlocked = verified;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const _LaunchLoadingScreen();
    }

    if (_unlocked) {
      return widget.child;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070A16),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 34,
                  color: Color(0xFFF2F4FF),
                ),
                const SizedBox(height: 14),
                const Text(
                  'MindSpend is locked',
                  style: TextStyle(
                    color: Color(0xFFF2F4FF),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use Face ID or fingerprint to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9CA3B2)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _checkLock,
                  child: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchLoadingScreen extends StatelessWidget {
  const _LaunchLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070A16),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'MindSpend',
                style: TextStyle(
                  color: Color(0xFFF2F4FF),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32D99A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MindSpendApp extends ConsumerWidget {
  const MindSpendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MindSpend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
