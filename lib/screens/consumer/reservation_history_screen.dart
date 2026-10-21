import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/stat_tile.dart';

class ReservationHistoryScreen extends StatelessWidget {
  const ReservationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tu índice de impacto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              icon: Icons.savings_outlined,
                              value: currency.format(provider.totalSavedQ),
                              label: 'Ahorrados',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                              icon: Icons.eco_outlined,
                              value: '${provider.totalKgRescued.toStringAsFixed(1)} kg',
                              label: 'Comida rescatada',
                              color: AppTheme.accentOrange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                              icon: Icons.receipt_long_outlined,
                              value: '${provider.totalOrders}',
                              label: 'Pedidos',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: provider.reservations.isEmpty
                      ? const Center(
                          child: Text('Aún no tienes reservas.\n¡Ve a rescatar tu primera canasta!',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: provider.reservations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => _ReservationTile(
                            reservation: provider.reservations[i],
                            currency: currency,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final NumberFormat currency;
  const _ReservationTile({required this.reservation, required this.currency});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(reservation.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusInfo.color.withValues(alpha: 0.15),
          child: Icon(statusInfo.icon, color: statusInfo.color),
        ),
        title: Text(reservation.basketTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${reservation.merchantName} · ${reservation.quantity}x · '
          '${DateFormat('dd/MM hh:mm a').format(reservation.createdAt)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currency.format(reservation.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(statusInfo.label, style: TextStyle(fontSize: 11, color: statusInfo.color)),
          ],
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return _StatusInfo('Pendiente', Icons.hourglass_empty, Colors.orange);
      case ReservationStatus.confirmed:
        return _StatusInfo('Por recoger', Icons.qr_code, AppTheme.primaryGreen);
      case ReservationStatus.pickedUp:
        return _StatusInfo('Recogido', Icons.check_circle, Colors.blueGrey);
      case ReservationStatus.cancelled:
        return _StatusInfo('Cancelado', Icons.cancel, Colors.red);
    }
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  _StatusInfo(this.label, this.icon, this.color);
}
