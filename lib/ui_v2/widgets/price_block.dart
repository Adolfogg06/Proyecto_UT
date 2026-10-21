import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/tanda_colors.dart';

final _currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

/// Precio original tachado + precio vigente en verde — usado en tarjetas y
/// en el detalle (con tamaños distintos vía [large]).
class PriceBlock extends StatelessWidget {
  final double original;
  final double current;
  final bool large;
  final CrossAxisAlignment alignment;

  const PriceBlock({
    super.key,
    required this.original,
    required this.current,
    this.large = false,
    this.alignment = CrossAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    if (large) {
      return Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (original > current)
            Text(
              _currency.format(original),
              style: TextStyle(fontSize: 14, color: c.muted, decoration: TextDecoration.lineThrough),
            ),
          Text(
            _currency.format(current),
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: c.green, letterSpacing: -0.5),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (original > current) ...[
          Text(
            _currency.format(original),
            style: TextStyle(fontSize: 13, color: c.muted, decoration: TextDecoration.lineThrough),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          _currency.format(current),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.green, letterSpacing: -0.3),
        ),
      ],
    );
  }
}
