import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/utils/pricing_engine.dart';
import '../../models/basket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/basket_provider.dart';
import '../../providers/reservation_provider.dart';
import '../theme/tanda_colors.dart';
import '../theme/tanda_theme.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/store_card.dart';
import 'store_detail_screen_v2.dart';

void openOfferV2(BuildContext context, String basketId) {
  final reservations = context.read<ReservationProvider>();
  final baskets = context.read<BasketProvider>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: reservations),
          ChangeNotifierProvider.value(value: baskets),
        ],
        child: StoreDetailScreenV2(basketId: basketId),
      ),
    ),
  );
}

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    final provider = context.watch<BasketProvider>();
    final offers = provider.filteredOffers;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onToggleMap: () => setState(() => _showMap = !_showMap), showingMap: _showMap),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TandaSpacing.screenMargin),
              child: _SearchField(provider: provider),
            ),
            const SizedBox(height: 14),
            FilterChipBar(
              options: ['Todos', ...provider.availableCategories],
              selected: provider.categoryFilter,
              onSelected: provider.setCategoryFilter,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(TandaSpacing.screenMargin, 18, TandaSpacing.screenMargin, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Última tanda de hoy',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: c.ink)),
                  Text('${offers.length} packs disponibles', style: TextStyle(fontSize: 13, color: c.muted)),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : offers.isEmpty
                      ? const _EmptyState()
                      : (_showMap ? _MapView(offers: offers, provider: provider) : _ListView(offers: offers, provider: provider)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onToggleMap;
  final bool showingMap;
  const _Header({required this.onToggleMap, required this.showingMap});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Padding(
      padding: const EdgeInsets.fromLTRB(TandaSpacing.screenMargin, 6, TandaSpacing.screenMargin, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECOGER CERCA DE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: c.muted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 18, color: c.green),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('Tu ubicación actual',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: showingMap ? 'Ver lista' : 'Ver mapa',
            onPressed: onToggleMap,
            icon: Icon(showingMap ? LucideIcons.search : LucideIcons.mapPin, color: c.ink),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: Icon(Icons.logout, color: c.muted, size: 20),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(LucideIcons.leaf, color: c.onGreen, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final BasketProvider provider;
  const _SearchField({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(TandaRadii.searchInput),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 18, color: c.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: provider.setSearchQuery,
              style: TextStyle(fontSize: 15, color: c.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Busca panaderías, sushi, fruta…',
                hintStyle: TextStyle(color: c.muted, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<Basket> offers;
  final BasketProvider provider;
  const _ListView({required this.offers, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: offers.length,
      itemBuilder: (context, i) {
        final basket = offers[i];
        return StoreCard(
          basket: basket,
          distanceKm: provider.distanceToUserKm(basket),
          now: provider.now,
          isFavorite: provider.isFavorite(basket.id),
          onTap: () => openOfferV2(context, basket.id),
          onToggleFavorite: () => provider.toggleFavorite(basket.id),
        );
      },
    );
  }
}

class _MapView extends StatelessWidget {
  final List<Basket> offers;
  final BasketProvider provider;
  const _MapView({required this.offers, required this.provider});

  @override
  Widget build(BuildContext context) {
    final center = provider.userLocation;
    final initialPosition = center != null ? LatLng(center.latitude, center.longitude) : const LatLng(14.5891, -90.5140);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialPosition, zoom: 13),
      myLocationEnabled: true,
      markers: offers.map((b) {
        final price = PricingEngine.currentPrice(b, provider.now);
        return Marker(
          markerId: MarkerId(b.id),
          position: LatLng(b.location.latitude, b.location.longitude),
          infoWindow: InfoWindow(
            title: b.title,
            snippet: 'Q${price.toStringAsFixed(2)} · ${b.merchantName}',
            onTap: () => openOfferV2(context, b.id),
          ),
        );
      }).toSet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No hay packs con ese filtro ahora mismo.\nPrueba otra categoría.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.muted, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}
