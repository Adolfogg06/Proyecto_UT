import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String accountStatus;
  final String displayName;
  final String phone;
  final DateTime createdAt;

  // Solo comercio
  final String businessName;
  final String businessAddress;
  final GeoPoint? businessLocation;
  final String businessPhotoUrl;

  /// Calificación del comercio (0 hasta que exista un sistema de reseñas).
  final double businessRating;
  final int businessReviewCount;

  // Solo consumidor — índice de impacto acumulado
  final double totalSavedQ;
  final double totalKgRescued;
  final int totalOrders;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.accountStatus = 'approved',
    required this.displayName,
    this.phone = '',
    DateTime? createdAt,
    this.businessName = '',
    this.businessAddress = '',
    this.businessLocation,
    this.businessPhotoUrl = '',
    this.businessRating = 0,
    this.businessReviewCount = 0,
    this.totalSavedQ = 0,
    this.totalKgRescued = 0,
    this.totalOrders = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      role: UserRoleX.fromValue(map['role'] ?? 'consumidor'),
      // Legacy demo merchant profiles predate review status; keep them usable.
      accountStatus: map['accountStatus'] ?? 'approved',
      displayName: map['displayName'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      businessName: map['businessName'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      businessLocation: map['businessLocation'] as GeoPoint?,
      businessPhotoUrl: map['businessPhotoUrl'] ?? '',
      businessRating: (map['businessRating'] ?? 0).toDouble(),
      businessReviewCount: (map['businessReviewCount'] ?? 0) as int,
      totalSavedQ: (map['totalSavedQ'] ?? 0).toDouble(),
      totalKgRescued: (map['totalKgRescued'] ?? 0).toDouble(),
      totalOrders: (map['totalOrders'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.value,
      'accountStatus': accountStatus,
      'displayName': displayName,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessLocation': businessLocation,
      'businessPhotoUrl': businessPhotoUrl,
      'businessRating': businessRating,
      'businessReviewCount': businessReviewCount,
      'totalSavedQ': totalSavedQ,
      'totalKgRescued': totalKgRescued,
      'totalOrders': totalOrders,
    };
  }

  bool get isComercio => role == UserRole.comercio;
  bool get isAdmin => role == UserRole.admin;
  bool get isMerchantPending => isComercio && accountStatus == 'pending';
  bool get isMerchantRejected => isComercio && accountStatus == 'rejected';
}
