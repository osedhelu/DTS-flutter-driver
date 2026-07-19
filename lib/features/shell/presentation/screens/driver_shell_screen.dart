import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../earnings/presentation/screens/earnings_screen.dart';
import '../../../offers/presentation/screens/driver_home_map_screen.dart';
import '../../../orders/presentation/screens/driver_orders_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class DriverShellScreen extends StatelessWidget {
  const DriverShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Ganancias',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const DriverHomeMapScreen();
}

class ShellOrdersScreen extends StatelessWidget {
  const ShellOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => const DriverOrdersScreen();
}

class ShellEarningsScreen extends StatelessWidget {
  const ShellEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) => const EarningsScreen();
}

class ShellProfileScreen extends StatelessWidget {
  const ShellProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
