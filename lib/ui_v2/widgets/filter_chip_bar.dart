import 'package:flutter/material.dart';
import '../theme/tanda_colors.dart';

/// Fila de chips de filtro con scroll horizontal — ver README, sección
/// "Filtros rápidos". Activo: fondo ink. Inactivo: borde line.
class FilterChipBar extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const FilterChipBar({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = options[i];
          final isActive = label == 'Todos' ? selected == null : selected == label;
          return GestureDetector(
            onTap: () => onSelected(label == 'Todos' ? null : label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? c.ink : c.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: isActive ? c.ink : c.line),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? c.bg : c.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
