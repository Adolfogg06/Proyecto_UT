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
    };
  }

  bool get isSoldOut => quantityAvailable <= 0;

  bool isWithinPickupWindow(DateTime now) =>
      now.isAfter(pickupWindowStart) && now.isBefore(pickupWindowEnd);
}
