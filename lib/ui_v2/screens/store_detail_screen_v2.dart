import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/utils/pricing_engine.dart';
import '../../models/basket.dart';
import '../../providers/basket_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../screens/consumer/payment_screen.dart';
import '../../services/firestore_service.dart';
import '../theme/tanda_colors.dart';
import '../theme/tanda_theme.dart';
import '../widgets/metric_tile.dart';
import '../widgets/pickup_window_card.dart';
import '../widgets/price_block.dart';
import '../widgets/scarcity_tag.dart';

class StoreDetailScreenV2 extends StatefulWidget {
  final String basketId;
  const StoreDetailScreenV2({super.key, required this.basketId});

  @override
  State<StoreDetailScreenV2> createState() => _StoreDetailScreenV2State();
}

class _StoreDetailScreenV2State extends State<StoreDetailScreenV2> {
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
    if (!mounted) return;
    setState(() {
      _basket = basket;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    if (_loading) return Scaffold(backgroundColor: c.bg, body: const Center(child: CircularProgressIndicator()));
    final basket = _basket;
    if (basket == null) {
      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(),
        body: Center(child: Text('Esta oferta ya no está disponible', style: TextStyle(color: c.muted))),
      );
    }

    final basketProvider = context.watch<BasketProvider>();
    final now = basketProvider.now;
    final price = PricingEngine.currentPrice(basket, now);
    final maxQty = basket.quantityAvailable.clamp(0, 10);
    final hasReviews = basket.merchantReviewCount > 0;
    final distanceKm = basketProvider.distanceToUserKm(basket);

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: basket.photoUrl.isNotEmpty
                          ? CachedNetworkImage(imageUrl: basket.photoUrl, fit: BoxFit.cover)
                          : Container(
                              color: c.ph1,
                              alignment: Alignment.center,
                              child: Icon(LucideIcons.shoppingBag, color: c.ph2, size: 40),
                            ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _roundButton(c, icon: LucideIcons.arrowLeft, onTap: () => Navigator.of(context).pop()),
                            _roundButton(
                              c,
                              icon: LucideIcons.heart,
                              filled: basketProvider.isFavorite(basket.id),
                              color: c.red,
                              onTap: () => basketProvider.toggleFavorite(basket.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(TandaRadii.detailSheet)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [if (basket.category.isNotEmpty) basket.category, '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km'].join(' · '),
                          style: TextStyle(fontSize: 13, color: c.muted, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          basket.title,
                          style: TextStyle(fontSize: 28, height: 1.08, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c.ink),
                        ),
                        if (hasReviews) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(LucideIcons.star, size: 16, color: c.yellow),
                              const SizedBox(width: 6),
                              Text(basket.merchantRating.toStringAsFixed(1),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                              const SizedBox(width: 4),
                              Text('(${basket.merchantReviewCount} reseñas)', style: TextStyle(color: c.muted)),
                            ],
                          ),
                        ],
                        const SizedBox(height: TandaSpacing.detailBlockGap),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.line),
                            borderRadius: BorderRadius.circular(TandaRadii.box),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('PACK SORPRESA',
                                      style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: c.green)),
                                  const SizedBox(height: 6),
                                  ScarcityTag(quantityAvailable: basket.quantityAvailable),
                                ],
                              ),
                              PriceBlock(original: basket.originalPrice, current: price, large: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: TandaSpacing.detailBlockGap),
                        PickupWindowCard(start: basket.pickupWindowStart, end: basket.pickupWindowEnd, now: now),
                        const SizedBox(height: TandaSpacing.detailBlockGap),
                        Text('¿Qué puede venir?',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.ink)),
                        const SizedBox(height: 10),
                        Text(
                          basket.description.isNotEmpty
                              ? basket.description
                              : 'Es comida excedente del día: lo que no se vendió hoy y sigue en perfecto estado. '
                                  'El contenido cambia cada tarde, por eso es sorpresa. '
                                  'Valor aproximado del pack: Q${basket.originalPrice.toStringAsFixed(2)}.',
                          style: TextStyle(fontSize: 15, height: 1.5, color: c.muted),
                        ),
                        if (basket.includes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: basket.includes
                                .map((inc) => Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: c.surface,
                                        border: Border.all(color: c.line),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(inc, style: TextStyle(fontSize: 13, color: c.ink)),
                                    ))
                                .toList(),
                          ),
                        ],
                        if (hasReviews) ...[
                          const SizedBox(height: TandaSpacing.detailBlockGap),
                          Text('Lo que dicen quienes rescatan aquí',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.ink)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                  child: MetricTile(
                                      value: '${basket.qualityMetrics.servicePercent.round()}%', label: 'Servicio rápido')),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: MetricTile(
                                      value: '${basket.qualityMetrics.quantityPercent.round()}%', label: 'Buena cantidad')),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: MetricTile(
                                      value: basket.qualityMetrics.qualityScore.toStringAsFixed(1), label: 'Calidad')),
                            ],
                          ),
                        ],
                        const SizedBox(height: TandaSpacing.detailBlockGap),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.line),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.mapPin, size: 20, color: c.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(basket.address.isNotEmpty ? basket.address : basket.merchantName,
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
                                    Text(
                                      'A ${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km · ${(distanceKm * 12).round()} min a pie',
                                      style: TextStyle(fontSize: 12, color: c.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [c.bg, c.bg.withValues(alpha: 0)],
                stops: const [0.65, 1],
              )),
              child: maxQty > 0
                  ? Row(
                      children: [
                        _QuantityStepper(
                          quantity: _quantity,
                          max: maxQty,
                          onChanged: (q) => setState(() => _quantity = q),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: context.read<ReservationProvider>(),
                                  child: PaymentScreen(basket: basket, quantity: _quantity),
                                ),
                              ),
                            ),
                            child: Text('Reservar por Q${(price * _quantity).toStringAsFixed(2)}'),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: null, child: Text('Agotado · avísame mañana')),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(TandaColors c, {required IconData icon, required VoidCallback onTap, bool filled = false, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: color ?? c.ink, fill: filled ? 1 : 0),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.quantity, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(TandaRadii.cta),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
            icon: Icon(Icons.remove, color: c.ink),
          ),
          Text('$quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
          IconButton(
            onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
            icon: Icon(Icons.add, color: c.ink),
          ),
        ],
      ),
    );
  }
}
