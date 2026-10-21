import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/basket.dart';
import '../models/reservation.dart';
import '../services/firestore_service.dart';

/// Panel del comercio: sus canastas activas/pasadas e ingreso recuperado.
class MerchantProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String merchantId;

  StreamSubscription<List<Basket>>? _basketsSub;
  StreamSubscription<List<Reservation>>? _reservationsSub;

  List<Basket> baskets = [];
  List<Reservation> reservations = [];
  bool isLoading = true;

  MerchantProvider(this.merchantId) {
    _basketsSub = _firestoreService.merchantBasketsStream(merchantId).listen((b) {
      baskets = b;
      isLoading = false;
      notifyListeners();
    });
    _reservationsSub =
        _firestoreService.merchantReservationsStream(merchantId).listen((r) {
      reservations = r;
      notifyListeners();
    });
  }

  List<Basket> get activeBaskets =>
      baskets.where((b) => b.status == BasketStatus.active).toList();

  double get totalRevenue =>
      reservations.fold(0.0, (sum, r) => sum + r.merchantNet);

  double get totalPlatformFees =>
      reservations.fold(0.0, (sum, r) => sum + r.platformFee);

  int get totalUnitsSold =>
      reservations.fold(0, (sum, r) => sum + r.quantity);

  Future<String> createBasket(Basket basket) {
    return _firestoreService.createBasket(basket);
  }

  Future<void> markSoldOut(String basketId) {
    return _firestoreService.updateBasketStatus(basketId, BasketStatus.soldOut);
  }

  @override
  void dispose() {
    _basketsSub?.cancel();
    _reservationsSub?.cancel();
    super.dispose();
  }
}
