import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/basket.dart';
import '../models/reservation.dart';
import '../services/firestore_service.dart';

/// Reservas del consumidor: historial + creación de una nueva reserva
/// (con pago simulado).
class ReservationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String consumerId;

  StreamSubscription<List<Reservation>>? _sub;
  List<Reservation> reservations = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  ReservationProvider(this.consumerId) {
    _sub = _firestoreService.consumerReservationsStream(consumerId).listen((r) {
      reservations = r;
      isLoading = false;
      notifyListeners();
    });
  }

  double get totalSavedQ =>
      reservations.fold(0.0, (sum, r) => sum + r.totalSaved);

  /// Aproximación: 0.35 kg rescatados por unidad (misma heurística que
  /// se usa al registrar la reserva en Firestore).
  double get totalKgRescued =>
      reservations.fold(0.0, (sum, r) => sum + r.quantity * 0.35);

  int get totalOrders => reservations.length;

  Future<Reservation?> reserve({
    required Basket basket,
    required int quantity,
    required double unitPrice,
    required PaymentMethod paymentMethod,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final reservation = await _firestoreService.createReservation(
        basket: basket,
        consumerId: consumerId,
        quantity: quantity,
        unitPrice: unitPrice,
        paymentMethod: paymentMethod,
      );
      return reservation;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
