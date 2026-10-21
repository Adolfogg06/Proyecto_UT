import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/utils/pricing_engine.dart';
import '../models/basket.dart';

/// Muestra el precio vigente de la canasta y se actualiza sola cada
/// minuto para reflejar en tiempo real las bajas de precio programadas.
class CountdownPriceWidget extends StatefulWidget {
  final Basket basket;
  const CountdownPriceWidget({super.key, required this.basket});

  @override
  State<CountdownPriceWidget> createState() => _CountdownPriceWidgetState();
}

class _CountdownPriceWidgetState extends State<CountdownPriceWidget> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');
    final price = PricingEngine.currentPrice(widget.basket, _now);
    final discount = PricingEngine.currentDiscountPercent(widget.basket, _now);
    final next = PricingEngine.nextTier(widget.basket, _now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currency.format(price),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                currency.format(widget.basket.originalPrice),
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${discount.round()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        if (next != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Baja a -${next.percentOff.round()}% a las '
              '${next.triggerTime.hour.toString().padLeft(2, '0')}:'
              '${next.triggerTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
