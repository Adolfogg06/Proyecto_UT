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
  StreamSubscription<double>? _fixedCostSub;

  List<Basket> baskets = [];
  List<Reservation> reservations = [];
  double fixedCostMonthly = 0;
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
    _fixedCostSub = _firestoreService.fixedCostMonthlyStream(merchantId).listen((v) {
      fixedCostMonthly = v;
      notifyListeners();
    });
  }

  Future<void> setFixedCostMonthly(double amount) =>
      _firestoreService.setFixedCostMonthly(merchantId, amount);

  // -------- Microeconomía de corto plazo, derivada de datos reales --------

  /// Costo variable unitario (CV): promedio del costo unitario que el
  /// comercio declaró al publicar cada canasta. 0 si nunca lo ha llenado.
  double get avgUnitCost {
    final withCost = baskets.where((b) => b.unitCost > 0).toList();
    if (withCost.isEmpty) return 0;
    return withCost.fold(0.0, (sum, b) => sum + b.unitCost) / withCost.length;
  }

  /// Precio de venta promedio. Si ya hay ventas reales, usa el precio
  /// efectivamente cobrado (más honesto); si no, cae al precio de lista de
  /// sus canastas activas como estimado — [sellPriceIsEstimate] lo señala.
  double get avgSellPrice {
    if (reservations.isNotEmpty) {
      return reservations.fold(0.0, (sum, r) => sum + r.unitPriceAtReservation) /
          reservations.length;
    }
    final active = baskets.where((b) => b.originalPrice > 0).toList();
    if (active.isEmpty) return 0;
    return active.fold(0.0, (sum, b) => sum + b.originalPrice) / active.length;
  }

  bool get sellPriceIsEstimate => reservations.isEmpty;

  /// Margen de contribución (Precio − CV). Si es 0 o negativo, el negocio
  /// nunca cubre sus costos fijos sin importar cuánto venda.
  double get contributionMargin => avgSellPrice - avgUnitCost;

  /// Punto de equilibrio en unidades: CF / (Precio − CV). Null si el margen
  /// de contribución no es positivo (no hay equilibrio posible).
  double? get breakEvenUnits {
    if (contributionMargin <= 0) return null;
    return fixedCostMonthly / contributionMargin;
  }

  double totalCostAt(double q) => fixedCostMonthly + avgUnitCost * q;
  double totalRevenueAt(double q) => avgSellPrice * q;

  /// Costo medio (CMe) en q unidades. Null si q es 0 (indefinido).
  double? avgCostAt(double q) => q > 0 ? totalCostAt(q) / q : null;

  /// Costo marginal (CMg): con el dato real disponible (costo unitario fijo
  /// por canasta) el costo de producir una unidad más es constante — por
  /// eso CMg = CV en este modelo de corto plazo.
  double get marginalCost => avgUnitCost;

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
    _fixedCostSub?.cancel();
    super.dispose();
  }
}
