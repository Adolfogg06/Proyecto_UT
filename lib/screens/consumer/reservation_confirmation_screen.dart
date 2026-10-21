import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/reservation.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  final Reservation reservation;
  const ReservationConfirmationScreen({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Reserva confirmada'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 72),
              const SizedBox(height: 16),
              Text(
                '¡Rescataste "${reservation.basketTitle}"!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Ahorraste ${currency.format(reservation.totalSaved)}',
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text('Código de recogida', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(
                      reservation.pickupCode,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Muestra este código en ${reservation.merchantName}\n'
                'entre ${timeFmt.format(reservation.pickupWindowStart)} y ${timeFmt.format(reservation.pickupWindowEnd)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Listo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
