import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils/pricing_engine.dart';
import '../models/basket.dart';

class OfferCard extends StatelessWidget {
  final Basket basket;
  final double distanceKm;
  final DateTime now;
  final VoidCallback onTap;

  const OfferCard({
    super.key,
    required this.basket,
    required this.distanceKm,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentPrice = PricingEngine.currentPrice(basket, now);
    final discount = PricingEngine.currentDiscountPercent(basket, now);
    final currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: basket.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: basket.photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            basket.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (basket.type == BasketType.sorpresa)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.card_giftcard, size: 16, color: AppTheme.accentOrange),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      basket.merchantName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          currency.format(basket.originalPrice),
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currency.format(currentPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DiscountBadge(percent: discount.round()),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km · ${basket.quantityAvailable} disp.',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() => Container(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGreen, size: 32),
      );
}

class _DiscountBadge extends StatelessWidget {
  final int percent;
  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
