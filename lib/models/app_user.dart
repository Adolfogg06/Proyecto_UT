import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String displayName;
  final String phone;
  final DateTime createdAt;

  // Solo comercio
  final String businessName;
  final String businessAddress;
  final GeoPoint? businessLocation;
  final String businessPhotoUrl;

  // Solo consumidor — índice de impacto acumulado
  final double totalSavedQ;
  final double totalKgRescued;
  final int totalOrders;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    this.phone = '',
    DateTime? createdAt,
    this.businessName = '',
    this.businessAddress = '',
    this.businessLocation,
    this.businessPhotoUrl = '',
    this.totalSavedQ = 0,
    this.totalKgRescued = 0,
    this.totalOrders = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      role: UserRoleX.fromValue(map['role'] ?? 'consumidor'),
      displayName: map['displayName'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      businessName: map['businessName'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      businessLocation: map['businessLocation'] as GeoPoint?,
      businessPhotoUrl: map['businessPhotoUrl'] ?? '',
      totalSavedQ: (map['totalSavedQ'] ?? 0).toDouble(),
      totalKgRescued: (map['totalKgRescued'] ?? 0).toDouble(),
      totalOrders: (map['totalOrders'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.value,
      'displayName': displayName,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessLocation': businessLocation,
      'businessPhotoUrl': businessPhotoUrl,
      'totalSavedQ': totalSavedQ,
      'totalKgRescued': totalKgRescued,
      'totalOrders': totalOrders,
    };
  }

  bool get isComercio => role == UserRole.comercio;
}
