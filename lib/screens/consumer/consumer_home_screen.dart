import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/utils/pricing_engine.dart';
import '../../models/basket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/basket_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/offer_card.dart';
import 'offer_detail_screen.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BasketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas cerca de ti'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? 'Ver lista' : 'Ver mapa',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(provider: provider),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredOffers.isEmpty
                    ? const _EmptyState()
                    : (_showMap
                        ? _MapView(offers: provider.filteredOffers, provider: provider)
                        : _ListView(offers: provider.filteredOffers, provider: provider)),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final BasketProvider provider;
  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.social_distance, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              const Text('Distancia:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppConstants.radiusFilterOptionsKm.map((km) {
                      final selected = provider.radiusKm == km;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${km.toInt()} km'),
                          selected: selected,
                          onSelected: (_) => provider.setRadius(km),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.percent, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              const Text('Descuento mín:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppConstants.discountFilterOptions.map((pct) {
                      final selected = provider.minDiscountPercent == pct;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(pct == 0 ? 'Todos' : '$pct%+'),
                          selected: selected,
                          onSelected: (_) => provider.setMinDiscount(pct),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _openOffer(BuildContext context, String basketId) {
  final reservations = context.read<ReservationProvider>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: reservations,
        child: OfferDetailScreen(basketId: basketId),
      ),
    ),
  );
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
        return OfferCard(
          basket: basket,
          distanceKm: provider.distanceToUserKm(basket),
          now: provider.now,
          onTap: () => _openOffer(context, basket.id),
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
    final initialPosition = center != null
        ? LatLng(center.latitude, center.longitude)
        : const LatLng(14.5891, -90.5140);

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
            onTap: () => _openOffer(context, b.id),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No hay ofertas con estos filtros por ahora.\nIntenta ampliar la distancia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
