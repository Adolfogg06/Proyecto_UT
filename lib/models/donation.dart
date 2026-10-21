import 'package:cloud_firestore/cloud_firestore.dart';

/// Donación de una canasta completa a un banco de alimentos / comedor
/// ("rescate solidario") en lugar de venderla.
class Donation {
  final String id;
  final String basketId;
  final String basketTitle;
  final String merchantId;
  final String merchantName;
  final String ngoId;
  final String ngoName;
  final int quantity;
  final DateTime createdAt;

  Donation({
    required this.id,
    required this.basketId,
    required this.basketTitle,
    required this.merchantId,
    required this.merchantName,
    required this.ngoId,
    required this.ngoName,
    required this.quantity,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Donation.fromMap(String id, Map<String, dynamic> map) {
    return Donation(
      id: id,
      basketId: map['basketId'] ?? '',
      basketTitle: map['basketTitle'] ?? '',
      merchantId: map['merchantId'] ?? '',
      merchantName: map['merchantName'] ?? '',
      ngoId: map['ngoId'] ?? '',
      ngoName: map['ngoName'] ?? '',
      quantity: (map['quantity'] ?? 0) as int,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'basketId': basketId,
      'basketTitle': basketTitle,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Ngo {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final String contact;

  Ngo({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.contact = '',
  });

  factory Ngo.fromMap(String id, Map<String, dynamic> map) {
    return Ngo(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      location: map['location'] as GeoPoint,
      contact: map['contact'] ?? '',
    );
  }
}
