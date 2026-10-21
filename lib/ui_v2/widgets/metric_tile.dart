import 'package:flutter/material.dart';
import '../theme/tanda_colors.dart';

/// Celda de la grilla "Lo que dicen quienes rescatan aquí" — ver README,
/// Detalle del comercio.
class MetricTile extends StatelessWidget {
  final String value;
  final String label;
  const MetricTile({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.ink)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, height: 1.25, color: c.muted)),
        ],
      ),
    );
  }
}
