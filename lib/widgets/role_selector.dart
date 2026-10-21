import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class RoleSelector extends StatelessWidget {
  final UserRole? selected;
  final ValueChanged<UserRole> onChanged;

  const RoleSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            icon: Icons.storefront,
            label: 'Comercio',
            description: 'Vendo comida sobrante',
            isSelected: selected == UserRole.comercio,
            onTap: () => onChanged(UserRole.comercio),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            icon: Icons.person,
            label: 'Consumidor',
            description: 'Busco ofertas cerca',
            isSelected: selected == UserRole.consumidor,
            onTap: () => onChanged(UserRole.consumidor),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: isSelected ? AppTheme.primaryGreen : Colors.grey[600]),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primaryGreen : Colors.black87)),
            const SizedBox(height: 2),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
