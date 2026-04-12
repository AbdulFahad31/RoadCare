import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'features/report/screens/home_screen.dart';
import 'features/report/screens/reports_list_screen.dart';
import 'features/report/screens/profile_screen.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);

    final screens = [
      const HomeScreen(),
      const ReportsListScreen(),
      isAdminAsync.valueOrNull == true
          ? const AdminDashboardScreen()
          : const ProfileScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Map',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_outlined),
        activeIcon: Icon(Icons.list_alt),
        label: 'Reports',
      ),
      BottomNavigationBarItem(
        icon: Icon(isAdminAsync.valueOrNull == true
            ? Icons.admin_panel_settings_outlined
            : Icons.person_outline),
        activeIcon: Icon(isAdminAsync.valueOrNull == true
            ? Icons.admin_panel_settings
            : Icons.person),
        label: isAdminAsync.valueOrNull == true ? 'Admin' : 'Profile',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }
}
