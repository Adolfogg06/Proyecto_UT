import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/basket.dart';
import '../models/donation.dart';
import '../models/app_user.dart';
import '../models/reservation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AppUser>> pendingMerchantApplicationsStream() {
    return _db
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'comercio')
        .where('accountStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> reviewMerchantApplication({
    required String merchantId,
    required String adminId,
    required bool approve,
  }) {
    return _db.collection(FirestoreCollections.users).doc(merchantId).update({
      'accountStatus': approve ? 'approved' : 'rejected',
      'reviewedAt': Timestamp.now(),
      'reviewedBy': adminId,
    });
  }

  // ---------------- Baskets (canastas) ----------------

  Stream<List<Basket>> activeBasketsStream() {
    return _db
        .collection(FirestoreCollections.baskets)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Basket.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Basket>> merchantBasketsStream(String merchantId) {
    return _db
        .collection(FirestoreCollections.baskets)
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Basket.fromMap(d.id, d.data())).toList());
  }

  Future<Basket?> getBasket(String basketId) async {
    final doc =
        await _db.collection(FirestoreCollections.baskets).doc(basketId).get();
    if (!doc.exists) return null;
    return Basket.fromMap(doc.id, doc.data()!);
  }

  Future<String> createBasket(Basket basket) async {
    final ref = await _db
        .collection(FirestoreCollections.baskets)
        .add(basket.toMap());
    return ref.id;
  }

  Future<void> updateBasketStatus(String basketId, BasketStatus status) {
    return _db
        .collection(FirestoreCollections.baskets)
        .doc(basketId)
        .update({'status': status.value});
  }

  // ---------------- Favorites ----------------

  String _favoriteDocId(String consumerId, String basketId) => '${consumerId}_$basketId';

  /// IDs de canastas marcadas como favoritas por [consumerId], en tiempo real.
  Stream<Set<String>> favoriteBasketIdsStream(String consumerId) {
    return _db
        .collection(FirestoreCollections.favorites)
        .where('consumerId', isEqualTo: consumerId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()['basketId'] as String).toSet());
  }

  Future<void> toggleFavorite({
    required String consumerId,
    required String basketId,
    required bool isFavorite,
  }) async {
    final ref = _db
        .collection(FirestoreCollections.favorites)
        .doc(_favoriteDocId(consumerId, basketId));
    if (isFavorite) {
      await ref.delete();
    } else {
      await ref.set({
        'consumerId': consumerId,
        'basketId': basketId,
        'createdAt': Timestamp.now(),
      });
    }
  }

  /// Distancia en km entre dos puntos (fórmula de Haversine), usada para
  /// filtrar canastas cercanas sin depender de índices geoespaciales.
  static double distanceKm(GeoPoint a, GeoPoint b) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(a.latitude)) *
            cos(_deg2rad(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadiusKm * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _deg2rad(double deg) => deg * (pi / 180);

  // ---------------- Reservations ----------------

  Stream<List<Reservation>> consumerReservationsStream(String consumerId) {
    return _db
        .collection(FirestoreCollections.reservations)
        .where('consumerId', isEqualTo: consumerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Reservation.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<Reservation>> merchantReservationsStream(String merchantId) {
    return _db
        .collection(FirestoreCollections.reservations)
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Reservation.fromMap(d.id, d.data()))
            .toList());
  }

  /// Crea la reserva y descuenta el inventario de la canasta en una
  /// transacción atómica (evita sobreventa por reservas concurrentes).
  Future<Reservation> createReservation({
    required Basket basket,
    required String consumerId,
    required int quantity,
    required double unitPrice,
    required PaymentMethod paymentMethod,
  }) async {
    final reservationRef =
        _db.collection(FirestoreCollections.reservations).doc();
    final basketRef =
        _db.collection(FirestoreCollections.baskets).doc(basket.id);

    final pickupCode = _generatePickupCode();
    final totalPrice = unitPrice * quantity;
    final platformFee = totalPrice * AppConstants.platformFeePercent / 100;
    final merchantNet = totalPrice - platformFee;

    final reservation = Reservation(
      id: reservationRef.id,
      basketId: basket.id,
      basketTitle: basket.title,
      basketPhotoUrl: basket.photoUrl,
      consumerId: consumerId,
      merchantId: basket.merchantId,
      merchantName: basket.merchantName,
      quantity: quantity,
      unitPriceAtReservation: unitPrice,
      originalUnitPrice: basket.originalPrice,
      totalPrice: totalPrice,
      platformFee: platformFee,
      merchantNet: merchantNet,
      paymentMethod: paymentMethod,
      pickupCode: pickupCode,
      pickupWindowStart: basket.pickupWindowStart,
      pickupWindowEnd: basket.pickupWindowEnd,
    );

    await _db.runTransaction((tx) async {
      final basketSnap = await tx.get(basketRef);
      final available = (basketSnap.data()?['quantityAvailable'] ?? 0) as int;
      if (available < quantity) {
        throw Exception('Ya no hay suficientes unidades disponibles');
      }
      final newAvailable = available - quantity;
      tx.update(basketRef, {
        'quantityAvailable': newAvailable,
        'lastReservationId': reservationRef.id,
        if (newAvailable <= 0) 'status': BasketStatus.soldOut.value,
      });
      tx.set(reservationRef, reservation.toMap());

    });

    return reservation;
  }

  Future<void> markPickedUp(String reservationId) {
    return _db
        .collection(FirestoreCollections.reservations)
        .doc(reservationId)
        .update({'status': ReservationStatus.pickedUp.value});
  }

  String _generatePickupCode() {
    final rand = Random.secure();
    return List.generate(4, (_) => rand.nextInt(10)).join();
  }

  // ---------------- Cost settings (panel de microeconomía) ----------------

  /// Costo fijo mensual que el propio comercio ingresa (0 si nunca lo ha
  /// configurado). El resto de las curvas de corto plazo se derivan de sus
  /// canastas y reservas reales, no de este documento.
  Stream<double> fixedCostMonthlyStream(String merchantId) {
    return _db
        .collection(FirestoreCollections.costSettings)
        .doc(merchantId)
        .snapshots()
        .map((snap) => (snap.data()?['fixedCostMonthly'] ?? 0).toDouble());
  }

  Future<void> setFixedCostMonthly(String merchantId, double amount) {
    return _db
        .collection(FirestoreCollections.costSettings)
        .doc(merchantId)
        .set({'fixedCostMonthly': amount});
  }

  // ---------------- Donations (rescate solidario) ----------------

  Stream<List<Ngo>> ngosStream() {
    return _db
        .collection(FirestoreCollections.ngos)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ngo.fromMap(d.id, d.data())).toList());
  }

  Future<void> donateBasket({
    required Basket basket,
    required Ngo ngo,
  }) async {
    final basketRef =
        _db.collection(FirestoreCollections.baskets).doc(basket.id);
    final donationRef =
        _db.collection(FirestoreCollections.donations).doc();

    final donation = Donation(
      id: donationRef.id,
      basketId: basket.id,
      basketTitle: basket.title,
      merchantId: basket.merchantId,
      merchantName: basket.merchantName,
      ngoId: ngo.id,
      ngoName: ngo.name,
      quantity: basket.quantityAvailable,
    );

    await _db.runTransaction((tx) async {
      tx.update(basketRef, {
        'status': BasketStatus.donated.value,
        'quantityAvailable': 0,
        'lastDonationId': donationRef.id,
      });
      tx.set(donationRef, donation.toMap());
    });
  }
}
