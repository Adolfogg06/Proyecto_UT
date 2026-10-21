import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils/pricing_engine.dart';
import '../../models/basket.dart';
import '../../providers/reservation_provider.dart';
import 'reservation_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Basket basket;
  final int quantity;
  const PaymentScreen({super.key, required this.basket, required this.quantity});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.qrBancario;

  Future<void> _confirm() async {
    final now = DateTime.now();
    final unitPrice = PricingEngine.currentPrice(widget.basket, now);
    final provider = context.read<ReservationProvider>();

    final reservation = await provider.reserve(
      basket: widget.basket,
      quantity: widget.quantity,
      unitPrice: unitPrice,
      paymentMethod: _method,
    );

    if (!mounted) return;
    if (reservation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'No se pudo completar la reserva')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ReservationConfirmationScreen(reservation: reservation)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');
    final unitPrice = PricingEngine.currentPrice(widget.basket, DateTime.now());
    final total = unitPrice * widget.quantity;
    final provider = context.watch<ReservationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.basket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _row('Cantidad', '${widget.quantity}'),
                      _row('Precio unitario', currency.format(unitPrice)),
                      const Divider(),
                      _row('Total a pagar', currency.format(total), bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioGroup<PaymentMethod>(
                groupValue: _method,
                onChanged: (v) => setState(() => _method = v!),
                child: Column(
                  children: PaymentMethod.values
                      .map((m) => RadioListTile<PaymentMethod>(
                            value: m,
                            title: Text(m.label),
                            secondary: Icon(_iconFor(m)),
                            activeColor: AppTheme.primaryGreen,
                          ))
                      .toList(),
                ),
              ),
              const Spacer(),
              if (_method != PaymentMethod.efectivoAlRecoger)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Pago simulado: en este prototipo no se procesa un cobro real.',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: provider.isSubmitting ? null : _confirm,
                child: provider.isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Confirmar y pagar ${currency.format(total)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.qrBancario:
        return Icons.qr_code;
      case PaymentMethod.billeteraDigital:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.efectivoAlRecoger:
        return Icons.payments_outlined;
    }
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
