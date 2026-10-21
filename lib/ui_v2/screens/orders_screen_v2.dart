import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../theme/tanda_colors.dart';
import '../theme/tanda_theme.dart';
import 'pickup_screen_v2.dart';

final _currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

void openPickupV2(BuildContext context, String reservationId) {
  final reservations = context.read<ReservationProvider>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: reservations,
        child: PickupScreenV2(reservationId: reservationId),
      ),
    ),
  );
}

class OrdersScreenV2 extends StatelessWidget {
  final VoidCallback onExplore;
  const OrdersScreenV2({super.key, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    final provider = context.watch<ReservationProvider>();
    final active = provider.reservations.where((r) => r.status == ReservationStatus.confirmed).toList();
    final past = provider.reservations.where((r) => r.status == ReservationStatus.pickedUp).toList();
    final saved = provider.totalOrders;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                    TandaSpacing.screenMargin, 18, TandaSpacing.screenMargin, 110),
                children: [
                  Text('Pedidos', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c.ink)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Icon(LucideIcons.leaf, color: c.onGreen, size: 34),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              saved == 1 ? '1 pack salvado' : '$saved packs salvados',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.onGreen),
                            ),
                            Text(
                              '≈ ${(saved * 2.5).toStringAsFixed(1).replaceAll('.', ',')} kg CO₂e evitados',
                              style: TextStyle(fontSize: 13, color: c.onGreen),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('POR RECOGER',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: c.muted)),
                  const SizedBox(height: 10),
                  if (active.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.line, width: 1.5, style: BorderStyle.solid),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No tienes reservas activas. Los mejores packs se van antes de las 20:00.',
                            style: TextStyle(fontSize: 15, height: 1.45, color: c.muted),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.ink,
                              foregroundColor: c.bg,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            onPressed: onExplore,
                            child: const Text('Explorar packs'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...active.map((r) => _ActiveTile(reservation: r)),
                  const SizedBox(height: 22),
                  Text('HISTORIAL',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: c.muted)),
                  const SizedBox(height: 10),
                  if (past.isEmpty)
                    Text('Aún no has recogido ningún pack.', style: TextStyle(color: c.muted, fontSize: 13))
                  else
                    ...past.map((r) => _PastTile(reservation: r)),
                ],
              ),
      ),
    );
  }
}

class _ActiveTile extends StatelessWidget {
  final Reservation reservation;
  const _ActiveTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    String fmt(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => openPickupV2(context, reservation.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.green, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: c.ph1, borderRadius: BorderRadius.circular(14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reservation.basketTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                  Text('Hoy ${fmt(reservation.pickupWindowStart)} – ${fmt(reservation.pickupWindowEnd)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.green)),
                  Text(reservation.pickupCode, style: tandaMono(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(18)),
              child: Text('Recoger', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.onGreen)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastTile extends StatelessWidget {
  final Reservation reservation;
  const _PastTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.greenSoft, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(LucideIcons.check, color: c.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reservation.basketTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                Text('Recogido · ${DateFormat('dd/MM, hh:mm a', 'es').format(reservation.createdAt)}',
                    style: TextStyle(fontSize: 12, color: c.muted)),
              ],
            ),
          ),
          Text(_currency.format(reservation.totalPrice), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
        ],
      ),
    );
  }
}
