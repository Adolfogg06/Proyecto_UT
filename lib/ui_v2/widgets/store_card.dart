import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/utils/pricing_engine.dart';
import '../../models/basket.dart';
import '../theme/tanda_colors.dart';
import '../theme/tanda_theme.dart';
import 'price_block.dart';
import 'scarcity_tag.dart';

String _distanceLabel(double km) => '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

String _pickupLabel(Basket b) {
  String fmt(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return 'Hoy ${fmt(b.pickupWindowStart)} – ${fmt(b.pickupWindowEnd)}';
}

Widget _placeholderImage(TandaColors c) {
  return Container(
    color: c.ph1,
    alignment: Alignment.center,
    child: Icon(LucideIcons.shoppingBag, color: c.ph2, size: 28),
  );
}

Widget _basketImage(Basket basket, TandaColors c) {
  if (basket.photoUrl.isEmpty) return _placeholderImage(c);
  return CachedNetworkImage(
    imageUrl: basket.photoUrl,
    fit: BoxFit.cover,
    placeholder: (_, __) => _placeholderImage(c),
    errorWidget: (_, __, ___) => _placeholderImage(c),
  );
}

/// Tarjeta de oferta en la lista de Inicio — variantes "grande" (1a) y
/// "compacta" (1b), ver README.
class StoreCard extends StatelessWidget {
  final Basket basket;
  final double distanceKm;
  final DateTime now;
  final bool isFavorite;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const StoreCard({
    super.key,
    required this.basket,
    required this.distanceKm,
    required this.now,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    final price = PricingEngine.currentPrice(basket, now);
    final opacity = basket.isSoldOut ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: compact ? _compact(context, c, price) : _large(context, c, price),
    );
  }

  Widget _favoriteButton(TandaColors c, {required double size, required bool circleBg}) {
    final button = IconButton(
      onPressed: onToggleFavorite,
      icon: Icon(
        isFavorite ? LucideIcons.heart : LucideIcons.heart,
        size: size,
        color: c.red,
        fill: isFavorite ? 1 : 0,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
    );
    if (!circleBg) return button;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: button,
    );
  }

  Widget _large(BuildContext context, TandaColors c, double price) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(TandaRadii.card),
          border: Border.all(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  Positioned.fill(child: _basketImage(basket, c)),
                  Positioned(top: 12, left: 12, child: ScarcityTag(quantityAvailable: basket.quantityAvailable)),
                  Positioned(top: 10, right: 10, child: _favoriteButton(c, size: 18, circleBg: true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(basket.title,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: c.ink)),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (basket.category.isNotEmpty) basket.category,
                                _distanceLabel(distanceKm),
                              ].join(' · '),
                              style: TextStyle(fontSize: 13, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      if (basket.merchantReviewCount > 0) ...[
                        const SizedBox(width: 10),
                        Icon(LucideIcons.star, size: 15, color: c.yellow),
                        const SizedBox(width: 3),
                        Text(basket.merchantRating.toStringAsFixed(1),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: c.line),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 15, color: c.green),
                          const SizedBox(width: 6),
                          Text(_pickupLabel(basket), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink)),
                        ],
                      ),
                      PriceBlock(original: basket.originalPrice, current: price),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compact(BuildContext context, TandaColors c, double price) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(TandaRadii.cardCompact),
          border: Border.all(color: c.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(TandaRadii.imageCompact),
              child: SizedBox(width: 96, height: 112, child: _basketImage(basket, c)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(basket.title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: c.ink)),
                      ),
                      _favoriteButton(c, size: 18, circleBg: false),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (basket.merchantReviewCount > 0) ...[
                        Icon(LucideIcons.star, size: 12, color: c.yellow),
                        const SizedBox(width: 4),
                        Text(basket.merchantRating.toStringAsFixed(1),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.ink)),
                        const SizedBox(width: 4),
                        Text('· ${_distanceLabel(distanceKm)}', style: TextStyle(fontSize: 12, color: c.muted)),
                      ] else
                        Text(_distanceLabel(distanceKm), style: TextStyle(fontSize: 12, color: c.muted)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 13, color: c.green),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(_pickupLabel(basket),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ScarcityTag(quantityAvailable: basket.quantityAvailable, compact: true),
                      PriceBlock(original: basket.originalPrice, current: price),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
