import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/setup/setup_form_screen.dart';
import '../features/home/home_shell.dart';
import '../features/price/price_input_screen.dart';
import '../features/cooloff/cool_off_screen.dart';
import '../features/results/results_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/goals_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(appAuthStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;

      // Allow cool-off and results screens through without redirect
      if (path == '/cooloff' || path == '/results') return null;

      switch (authState) {
        case AppAuthState.loading:
          return null; // Stay on current page while loading
        case AppAuthState.unauthenticated:
          if (path == '/' || path == '/auth') return null;
          return '/';
        case AppAuthState.needsVerification:
          return '/verify-email';
        case AppAuthState.needsProfile:
          if (path == '/setup') return null;
          return '/setup';
        case AppAuthState.ready:
        case AppAuthState.guest:
          if (path == '/' || path == '/auth' || path == '/setup') {
            return '/home/check';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupFormScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home/check',
            builder: (context, state) => const PriceInputScreen(),
          ),
          GoRoute(
            path: '/home/insights',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/cooloff',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return CoolOffScreen(
            price: extras['price'] as double? ?? 0,
            label: extras['label'] as String? ?? '',
            category: extras['category'] as String? ?? 'other',
          );
        },
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return ResultsScreen(
            price: extras['price'] as double? ?? 0,
            label: extras['label'] as String? ?? '',
            category: extras['category'] as String? ?? 'other',
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
    ],
  );
});
