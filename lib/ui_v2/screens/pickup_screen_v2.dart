import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../theme/tanda_colors.dart';
import '../theme/tanda_theme.dart';
import '../widgets/swipe_to_confirm.dart';

final _currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

/// Pantalla de validación en tienda — nueva en el rediseño, no existía en
/// la app original. El consumidor muestra el código al personal y confirma
/// la recogida él mismo con el deslizador antifraude; la tira "EN VIVO"
/// con reloj real evita que una captura de pantalla sirva como comprobante.
class PickupScreenV2 extends StatefulWidget {
  final String reservationId;
  const PickupScreenV2({super.key, required this.reservationId});

  @override
  State<PickupScreenV2> createState() => _PickupScreenV2State();
}

class _PickupScreenV2State extends State<PickupScreenV2> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    final provider = context.watch<ReservationProvider>();
    final matches = provider.reservations.where((r) => r.id == widget.reservationId);
    final reservation = matches.isEmpty ? null : matches.first;

    if (reservation == null) {
      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(),
        body: Center(child: Text('Esta reserva ya no está disponible', style: TextStyle(color: c.muted))),
      );
    }

    final isPending = reservation.status == ReservationStatus.confirmed;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(TandaSpacing.screenMargin, 4, TandaSpacing.screenMargin, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundButton(c, icon: LucideIcons.arrowLeft, onTap: () => Navigator.of(context).pop()),
                  Text('Recogida en tienda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                  const SizedBox(width: 42),
                ],
              ),
              const SizedBox(height: 14),
              _LiveClockPill(now: _now),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: _Receipt(reservation: reservation),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: isPending
                    ? SwipeToConfirm(onConfirm: () => provider.markPickedUp(reservation.id))
                    : _RedeemedBanner(reservation: reservation),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundButton(TandaColors c, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, border: Border.all(color: c.line)),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: c.ink),
      ),
    );
  }
}

class _LiveClockPill extends StatelessWidget {
  final DateTime now;
  const _LiveClockPill({required this.now});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    String two(int n) => n.toString().padLeft(2, '0');
    final clock = '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(17)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: c.red),
          const SizedBox(width: 8),
          Text('EN VIVO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: c.ink)),
          const SizedBox(width: 8),
          Text(clock, style: tandaMono(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink)),
          const SizedBox(width: 8),
          Text('· no válido en captura', style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: 1 - _controller.value * 0.6,
        child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  final Reservation reservation;
  const _Receipt({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    String fmt(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              children: [
                Text('PACK SORPRESA · x${reservation.quantity}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: c.green)),
                const SizedBox(height: 4),
                Text(reservation.basketTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.ink)),
                Text(reservation.merchantName, style: TextStyle(fontSize: 13, color: c.muted)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(14)),
                  child: Text(reservation.pickupCode,
                      style: tandaMono(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 4, color: c.ink)),
                ),
                const SizedBox(height: 8),
                Text('Muestra este código al personal', style: TextStyle(fontSize: 12, color: c.muted)),
              ],
            ),
          ),
          CustomPaint(
            painter: _PerforationPainter(c.bg),
            child: const SizedBox(height: 20, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                _row(c, 'Horario de recogida', 'Hoy ${fmt(reservation.pickupWindowStart)} – ${fmt(reservation.pickupWindowEnd)}'),
                _row(c, 'Valor original', _currency.format(reservation.originalUnitPrice * reservation.quantity),
                    strike: true),
                _row(c, 'Ahorro', '−${_currency.format(reservation.totalSaved)}', color: c.green, bold: true),
                Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Container(height: 1, color: c.line)),
                _row(c, 'Total pagado', _currency.format(reservation.totalPrice), bold: true, big: true),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reservation.paymentMethod.label, style: TextStyle(fontSize: 12, color: c.muted)),
                    Text('Pedido #${reservation.id.substring(0, reservation.id.length.clamp(0, 6))}',
                        style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(TandaColors c, String label, String value,
      {bool strike = false, bool bold = false, bool big = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: c.muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: big ? 22 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              decoration: strike ? TextDecoration.lineThrough : null,
              color: color ?? (strike ? c.muted : c.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dos semicírculos recortados a los lados + línea discontinua — el "ticket"
/// perforado del recibo.
class _PerforationPainter extends CustomPainter {
  final Color notchColor;
  _PerforationPainter(this.notchColor);

  @override
  void paint(Canvas canvas, Size size) {
    final notchPaint = Paint()..color = notchColor;
    canvas.drawCircle(Offset(0, size.height / 2), 11, notchPaint);
    canvas.drawCircle(Offset(size.width, size.height / 2), 11, notchPaint);

    final linePaint = Paint()
      ..color = notchColor.computeLuminance() > 0.5 ? const Color(0xFF2A2F2B) : const Color(0xFFE4E7E2)
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const gap = 5.0;
    double x = 20;
    final y = size.height / 2;
    while (x < size.width - 20) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), linePaint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter oldDelegate) => oldDelegate.notchColor != notchColor;
}

class _RedeemedBanner extends StatelessWidget {
  final Reservation reservation;
  const _RedeemedBanner({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.onGreen, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.check, color: c.green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Pack recogido!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.onGreen)),
                Text('≈ 2,5 kg CO₂e evitados', style: TextStyle(fontSize: 13, color: c.onGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
