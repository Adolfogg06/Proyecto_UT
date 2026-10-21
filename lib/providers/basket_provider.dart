import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../core/utils/pricing_engine.dart';
import '../models/basket.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

/// Ofertas cercanas para el consumidor: mapa/lista con filtro por
/// distancia y % de descuento. El precio de cada tarjeta se recalcula
/// cada tick de [_ticker] para reflejar la baja de precio en tiempo real.
class BasketProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  StreamSubscription<List<Basket>>? _sub;
  Timer? _ticker;

  List<Basket> _allActive = [];
  GeoPoint? _userLocation;

  double radiusKm = AppConstants.defaultSearchRadiusKm;
  int minDiscountPercent = 0;

  bool isLoading = true;
  DateTime now = DateTime.now();

  GeoPoint? get userLocation => _userLocation;

  BasketProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _userLocation = await _locationService.getCurrentLocation();
    } catch (_) {
      _userLocation = LocationService.guatemalaCityDefault;
    }
    _sub = _firestoreService.activeBasketsStream().listen((baskets) {
      _allActive = baskets;
      isLoading = false;
      notifyListeners();
    });
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      now = DateTime.now();
      notifyListeners();
    });
    notifyListeners();
  }

  List<Basket> get filteredOffers {
    if (_userLocation == null) return _allActive;
    return _allActive.where((b) {
      final distance = FirestoreService.distanceKm(_userLocation!, b.location);
      if (distance > radiusKm) return false;
      final discount = PricingEngine.currentDiscountPercent(b, now);
      if (discount < minDiscountPercent) return false;
      return !b.isSoldOut;
    }).toList()
      ..sort((a, b) => FirestoreService.distanceKm(_userLocation!, a.location)
          .compareTo(FirestoreService.distanceKm(_userLocation!, b.location)));
  }

  double distanceToUserKm(Basket basket) {
    if (_userLocation == null) return 0;
    return FirestoreService.distanceKm(_userLocation!, basket.location);
  }

  void setRadius(double km) {
    radiusKm = km;
    notifyListeners();
  }

  void setMinDiscount(int percent) {
    minDiscountPercent = percent;
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    try {
      _userLocation = await _locationService.getCurrentLocation();
      notifyListeners();
    } catch (_) {
      // se mantiene la última ubicación conocida
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
