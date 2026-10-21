import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/tanda_colors.dart';
import '../theme/tanda_theme.dart';

String _fmtHm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// "Abre en 1 h 13 min" / "Ventana abierta" / "Ventana cerrada" — ver README,
/// bloque horario de Detalle.
String pickupCountdownLabel(DateTime start, DateTime end, DateTime now) {
  if (now.isBefore(start)) {
    final diff = start.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return h > 0 ? 'Abre en $h h $m min' : 'Abre en $m min';
  }
  if (now.isAfter(end)) return 'Ventana cerrada';
  return 'Ventana abierta';
}

/// Bloque destacado "Recogida solo hoy" con la ventana horaria y la cuenta
/// atrás — ver README, Detalle del comercio.
class PickupWindowCard extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final DateTime now;
  const PickupWindowCard({super.key, required this.start, required this.end, required this.now});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.greenSoft, borderRadius: BorderRadius.circular(TandaRadii.pickupWindowBlock)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Icon(LucideIcons.clock, color: c.onGreen, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECOGIDA SOLO HOY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: c.green),
                  ),
                  Text(
                    '${_fmtHm(start)} – ${_fmtHm(end)}',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.ink),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(height: 1, color: c.greenLine),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Fuera de este horario el pack no se guarda.',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ),
                Text(
                  pickupCountdownLabel(start, end, now),
                  style: tandaMono(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
