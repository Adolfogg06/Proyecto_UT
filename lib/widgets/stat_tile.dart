import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppTheme.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
