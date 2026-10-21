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

  /// Si se da, habilita favoritos para este consumidor (opcional para no
  /// romper usos existentes de `BasketProvider()` sin sesión asociada).
  final String? consumerId;

  StreamSubscription<List<Basket>>? _sub;
  StreamSubscription<Set<String>>? _favSub;
  Timer? _ticker;

  List<Basket> _allActive = [];
  GeoPoint? _userLocation;
  Set<String> favoriteIds = {};

  double radiusKm = AppConstants.defaultSearchRadiusKm;
  int minDiscountPercent = 0;
  String searchQuery = '';
  String? categoryFilter; // null = "Todos"

  bool isLoading = true;
  DateTime now = DateTime.now();

  GeoPoint? get userLocation => _userLocation;

  BasketProvider({this.consumerId}) {
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
    if (consumerId != null) {
      _favSub = _firestoreService.favoriteBasketIdsStream(consumerId!).listen((ids) {
        favoriteIds = ids;
        notifyListeners();
      });
    }
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      now = DateTime.now();
      notifyListeners();
    });
    notifyListeners();
  }

  /// Categorías realmente presentes en las canastas activas cargadas
  /// (alimenta los chips de filtro — nunca se inventa una categoría vacía).
  List<String> get availableCategories => _allActive
      .map((b) => b.category)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  bool isFavorite(String basketId) => favoriteIds.contains(basketId);

  Future<void> toggleFavorite(String basketId) {
    if (consumerId == null) return Future.value();
    return _firestoreService.toggleFavorite(
      consumerId: consumerId!,
      basketId: basketId,
      isFavorite: isFavorite(basketId),
    );
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    categoryFilter = category;
    notifyListeners();
  }

  List<Basket> get filteredOffers {
    final q = searchQuery.trim().toLowerCase();
    Iterable<Basket> result = _allActive.where((b) {
      if (categoryFilter != null && b.category != categoryFilter) return false;
      if (q.isNotEmpty) {
        final haystack = '${b.title} ${b.merchantName} ${b.category}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      final discount = PricingEngine.currentDiscountPercent(b, now);
      if (discount < minDiscountPercent) return false;
      return !b.isSoldOut;
    });
    if (_userLocation != null) {
      result = result.where(
        (b) => FirestoreService.distanceKm(_userLocation!, b.location) <= radiusKm,
      );
    }
    final list = result.toList();
    if (_userLocation != null) {
      list.sort((a, b) => FirestoreService.distanceKm(_userLocation!, a.location)
          .compareTo(FirestoreService.distanceKm(_userLocation!, b.location)));
    }
    return list;
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
    _favSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
