import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

/// Franja horaria de descuento definida por el comercio.
/// Ej: a las 17:00 baja 30%, a las 18:30 baja 50%, a las 19:30 baja 70%.
class DiscountTier {
  final DateTime triggerTime; // solo se usa hour/minute
  final double percentOff;

  DiscountTier({required this.triggerTime, required this.percentOff});

  factory DiscountTier.fromMap(Map<String, dynamic> map) {
    final parts = (map['time'] as String).split(':');
    final now = DateTime.now();
    return DiscountTier(
      triggerTime: DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      ),
      percentOff: (map['percent'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    final hh = triggerTime.hour.toString().padLeft(2, '0');
    final mm = triggerTime.minute.toString().padLeft(2, '0');
    return {'time': '$hh:$mm', 'percent': percentOff};
  }
}

/// Métricas de calidad del comercio, calculadas a partir de reseñas
/// post-recogida. En 0 mientras no exista ninguna reseña (todavía no hay
/// pantalla para dejarlas) — la UI debe ocultar el bloque si [reviewCount]
/// del comercio es 0, en vez de mostrar un cero engañoso.
class QualityMetrics {
  final double servicePercent;
  final double quantityPercent;
  final double qualityScore;

  const QualityMetrics({
    this.servicePercent = 0,
    this.quantityPercent = 0,
    this.qualityScore = 0,
  });

  factory QualityMetrics.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const QualityMetrics();
    return QualityMetrics(
      servicePercent: (map['servicePercent'] ?? 0).toDouble(),
      quantityPercent: (map['quantityPercent'] ?? 0).toDouble(),
      qualityScore: (map['qualityScore'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'servicePercent': servicePercent,
        'quantityPercent': quantityPercent,
        'qualityScore': qualityScore,
      };
}

class Basket {
  final String id;
  final String merchantId;
  final String merchantName;
  final String title;
  final String description;
  final String photoUrl;
  final BasketType type;

  final double originalPrice;
  final double minPrice;
  final double unitCost;

  final int quantityTotal;
  final int quantityAvailable;

  final DateTime pickupWindowStart;
  final DateTime pickupWindowEnd;
  final List<DiscountTier> discountTiers;

  final GeoPoint location;
  final String address;
  final BasketStatus status;
  final DateTime createdAt;
  final String lastReservationId;
  final String lastDonationId;

  /// Calificación del comercio y nº de reseñas, copiados del perfil del
  /// comercio al momento de publicar (mismo patrón que [merchantName]).
  /// En 0 hasta que exista un sistema de reseñas real.
  final double merchantRating;
  final int merchantReviewCount;
  final QualityMetrics qualityMetrics;

  /// Ejemplos de productos que puede incluir la canasta, escritos por el
  /// comercio al publicar (p. ej. "Pan de masa madre", "Croissants").
  final List<String> includes;

  /// Categoría libre del comercio (p. ej. "Panadería", "Vegano"). Alimenta
  /// los chips de filtro de Inicio — se derivan de las categorías realmente
  /// presentes en los datos, no de una lista fija.
  final String category;

  Basket({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.title,
    this.description = '',
    this.photoUrl = '',
    this.type = BasketType.visible,
    required this.originalPrice,
    required this.minPrice,
    this.unitCost = 0,
    required this.quantityTotal,
    required this.quantityAvailable,
    required this.pickupWindowStart,
    required this.pickupWindowEnd,
    this.discountTiers = const [],
    required this.location,
    this.address = '',
    this.status = BasketStatus.active,
    DateTime? createdAt,
    this.lastReservationId = '',
    this.lastDonationId = '',
    this.merchantRating = 0,
    this.merchantReviewCount = 0,
    this.qualityMetrics = const QualityMetrics(),
    this.includes = const [],
    this.category = '',
  }) : createdAt = createdAt ?? DateTime.now();

  factory Basket.fromMap(String id, Map<String, dynamic> map) {
    return Basket(
      id: id,
      merchantId: map['merchantId'] ?? '',
      merchantName: map['merchantName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      type: BasketTypeX.fromValue(map['type'] ?? 'visible'),
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      minPrice: (map['minPrice'] ?? 0).toDouble(),
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      quantityTotal: (map['quantityTotal'] ?? 0) as int,
      quantityAvailable: (map['quantityAvailable'] ?? 0) as int,
      pickupWindowStart:
          (map['pickupWindowStart'] as Timestamp).toDate(),
      pickupWindowEnd: (map['pickupWindowEnd'] as Timestamp).toDate(),
      discountTiers: ((map['discountTiers'] ?? []) as List)
          .map((t) => DiscountTier.fromMap(Map<String, dynamic>.from(t)))
          .toList(),
      location: map['location'] as GeoPoint,
      address: map['address'] ?? '',
      status: BasketStatusX.fromValue(map['status'] ?? 'active'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastReservationId: map['lastReservationId'] ?? '',
      lastDonationId: map['lastDonationId'] ?? '',
      merchantRating: (map['merchantRating'] ?? 0).toDouble(),
      merchantReviewCount: (map['merchantReviewCount'] ?? 0) as int,
      qualityMetrics: QualityMetrics.fromMap(
        map['qualityMetrics'] as Map<String, dynamic>?,
      ),
      includes: ((map['includes'] ?? []) as List).map((e) => e.toString()).toList(),
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'merchantName': merchantName,
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'type': type.value,
      'originalPrice': originalPrice,
      'minPrice': minPrice,
      'unitCost': unitCost,
      'quantityTotal': quantityTotal,
      'quantityAvailable': quantityAvailable,
      'pickupWindowStart': Timestamp.fromDate(pickupWindowStart),
      'pickupWindowEnd': Timestamp.fromDate(pickupWindowEnd),
      'discountTiers': discountTiers.map((t) => t.toMap()).toList(),
      'location': location,
      'address': address,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastReservationId': lastReservationId,
      'lastDonationId': lastDonationId,
      'merchantRating': merchantRating,
      'merchantReviewCount': merchantReviewCount,
      'qualityMetrics': qualityMetrics.toMap(),
      'includes': includes,
      'category': category,
    };
  }

  bool get isSoldOut => quantityAvailable <= 0;

  bool isWithinPickupWindow(DateTime now) =>
      now.isAfter(pickupWindowStart) && now.isBefore(pickupWindowEnd);
}
