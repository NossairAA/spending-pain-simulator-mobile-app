import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

/// Bottom navigation shell — replaces web app's header
class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  static int _indexFromPath(String path) {
    if (path.startsWith('/home/insights')) return 0;
    if (path.startsWith('/home/check')) return 1;
    if (path.startsWith('/home/profile')) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromPath(location);
    final ext = context.colors;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: ext.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/home/insights');
              case 1:
                context.go('/home/check');
              case 2:
                context.go('/home/profile');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.barChart3),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.circleDollarSign),
              label: 'Check',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
