import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

/// Bottom navigation shell — replaces web app's header
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final ext = context.colors;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: ext.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == currentIndex,
            );
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
