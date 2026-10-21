import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class Reservation {
  final String id;
  final String basketId;
  final String basketTitle;
  final String basketPhotoUrl;
  final String consumerId;
  final String merchantId;
  final String merchantName;

  final int quantity;
  final double unitPriceAtReservation;
  final double originalUnitPrice;
  final double totalPrice;
  final double platformFeePercent;
  final double platformFee;
  final double merchantNet;

  final PaymentMethod paymentMethod;
  final String pickupCode;
  final ReservationStatus status;

  final DateTime pickupWindowStart;
  final DateTime pickupWindowEnd;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.basketId,
    required this.basketTitle,
    this.basketPhotoUrl = '',
    required this.consumerId,
    required this.merchantId,
    required this.merchantName,
    required this.quantity,
    required this.unitPriceAtReservation,
    required this.originalUnitPrice,
    required this.totalPrice,
    this.platformFeePercent = AppConstants.platformFeePercent,
    required this.platformFee,
    required this.merchantNet,
    required this.paymentMethod,
    required this.pickupCode,
    this.status = ReservationStatus.confirmed,
    required this.pickupWindowStart,
    required this.pickupWindowEnd,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalSaved => (originalUnitPrice - unitPriceAtReservation) * quantity;

  factory Reservation.fromMap(String id, Map<String, dynamic> map) {
    return Reservation(
      id: id,
      basketId: map['basketId'] ?? '',
      basketTitle: map['basketTitle'] ?? '',
      basketPhotoUrl: map['basketPhotoUrl'] ?? '',
      consumerId: map['consumerId'] ?? '',
      merchantId: map['merchantId'] ?? '',
      merchantName: map['merchantName'] ?? '',
      quantity: (map['quantity'] ?? 1) as int,
      unitPriceAtReservation: (map['unitPriceAtReservation'] ?? 0).toDouble(),
      originalUnitPrice: (map['originalUnitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      platformFeePercent: (map['platformFeePercent'] ??
              AppConstants.platformFeePercent)
          .toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      merchantNet: (map['merchantNet'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.value == (map['paymentMethod'] ?? 'cash'),
        orElse: () => PaymentMethod.efectivoAlRecoger,
      ),
      pickupCode: map['pickupCode'] ?? '',
      status: ReservationStatusX.fromValue(map['status'] ?? 'confirmed'),
      pickupWindowStart: (map['pickupWindowStart'] as Timestamp).toDate(),
      pickupWindowEnd: (map['pickupWindowEnd'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'basketId': basketId,
      'basketTitle': basketTitle,
      'basketPhotoUrl': basketPhotoUrl,
      'consumerId': consumerId,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'quantity': quantity,
      'unitPriceAtReservation': unitPriceAtReservation,
      'originalUnitPrice': originalUnitPrice,
      'totalPrice': totalPrice,
      'platformFeePercent': platformFeePercent,
      'platformFee': platformFee,
      'merchantNet': merchantNet,
      'paymentMethod': paymentMethod.value,
      'pickupCode': pickupCode,
      'status': status.value,
      'pickupWindowStart': Timestamp.fromDate(pickupWindowStart),
      'pickupWindowEnd': Timestamp.fromDate(pickupWindowEnd),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
