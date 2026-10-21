import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/basket_provider.dart';
import '../../providers/reservation_provider.dart';
import 'consumer_home_screen.dart';
import 'reservation_history_screen.dart';

/// Contenedor del flujo de consumidor: provee BasketProvider y
/// ReservationProvider (atados al usuario logueado) y navega entre
/// "Ofertas" y "Mis reservas" con una barra inferior.
class ConsumerShell extends StatefulWidget {
  const ConsumerShell({super.key});

  @override
  State<ConsumerShell> createState() => _ConsumerShellState();
}

class _ConsumerShellState extends State<ConsumerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().appUser!.uid;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BasketProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider(uid)),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            ConsumerHomeScreen(),
            ReservationHistoryScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Ofertas'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Mis reservas'),
          ],
        ),
      ),
    );
  }
}
