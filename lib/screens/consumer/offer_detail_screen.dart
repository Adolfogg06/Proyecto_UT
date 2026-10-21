import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/basket.dart';
import '../../providers/reservation_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/countdown_price_widget.dart';
import 'payment_screen.dart';

class OfferDetailScreen extends StatefulWidget {
  final String basketId;
  const OfferDetailScreen({super.key, required this.basketId});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final _firestoreService = FirestoreService();
  Basket? _basket;
  int _quantity = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final basket = await _firestoreService.getBasket(widget.basketId);
    setState(() {
      _basket = basket;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final basket = _basket;
    if (basket == null) {
      return const Scaffold(body: Center(child: Text('Esta oferta ya no está disponible')));
    }

    final maxQty = basket.quantityAvailable.clamp(0, 10);

    return Scaffold(
      appBar: AppBar(title: Text(basket.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: basket.photoUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: basket.photoUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: const Icon(Icons.shopping_bag_outlined, size: 60, color: AppTheme.primaryGreen),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(basket.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      if (basket.type == BasketType.sorpresa)
                        Chip(
                          label: const Text('Bolsa sorpresa'),
                          avatar: const Icon(Icons.card_giftcard, size: 16),
                          backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                        ),
                    ],
                  ),
                  Text(basket.merchantName, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  CountdownPriceWidget(basket: basket),
                  const SizedBox(height: 12),
                  if (basket.description.isNotEmpty) Text(basket.description),
                  const SizedBox(height: 16),
                  _InfoRow(icon: Icons.location_on_outlined, text: basket.address),
                  _InfoRow(
                    icon: Icons.schedule,
                    text: 'Recoger entre ${_formatTime(basket.pickupWindowStart)} y ${_formatTime(basket.pickupWindowEnd)}',
                  ),
                  _InfoRow(icon: Icons.inventory_2_outlined, text: '${basket.quantityAvailable} disponibles'),
                  const SizedBox(height: 20),
                  if (maxQty > 0) ...[
                    const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _quantity < maxQty ? () => setState(() => _quantity++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: context.read<ReservationProvider>(),
                              child: PaymentScreen(basket: basket, quantity: _quantity),
                            ),
                          ),
                        ),
                        child: const Text('Reservar'),
                      ),
                    ),
                  ] else
                    const Text('Sin disponibilidad', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
