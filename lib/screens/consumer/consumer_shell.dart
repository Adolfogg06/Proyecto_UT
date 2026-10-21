import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/basket_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../ui_v2/redesign_flag.dart';
import '../../ui_v2/screens/home_screen_v2.dart';
import '../../ui_v2/screens/orders_screen_v2.dart';
import '../../ui_v2/theme/tanda_colors.dart';
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
        ChangeNotifierProvider(create: (_) => BasketProvider(consumerId: uid)),
        ChangeNotifierProvider(create: (_) => ReservationProvider(uid)),
      ],
      // Builder: los providers de arriba solo existen por debajo de este
      // punto. El `context` del método build() es anterior al MultiProvider,
      // así que _buildRedesign/_buildLegacy necesitan un context nuevo
      // (ProviderNotFoundError si se usa el de afuera).
      child: Builder(
        builder: (context) => kUseRedesign ? _buildRedesign(context) : _buildLegacy(),
      ),
    );
  }

  Widget _buildLegacy() {
    return Scaffold(
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
    );
  }

  Widget _buildRedesign(BuildContext context) {
    final c = context.tanda;
    final activeCount = context
        .watch<ReservationProvider>()
        .reservations
        .where((r) => r.status == ReservationStatus.confirmed)
        .length;

    return Scaffold(
      backgroundColor: c.bg,
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreenV2(),
          OrdersScreenV2(onExplore: () => setState(() => _index = 0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(LucideIcons.home), label: 'Inicio'),
          NavigationDestination(
            icon: activeCount > 0
                ? Badge(label: Text('$activeCount'), child: const Icon(LucideIcons.shoppingBag))
                : const Icon(LucideIcons.shoppingBag),
            label: 'Pedidos',
          ),
        ],
      ),
    );
  }
}
