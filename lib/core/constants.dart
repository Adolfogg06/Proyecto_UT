class AppConstants {
  /// Comisión que retiene la plataforma sobre cada venta.
  static const double platformFeePercent = 15.0;

  static const double defaultSearchRadiusKm = 5.0;

  static const List<double> radiusFilterOptionsKm = [1, 2, 5, 10, 20];

  static const List<int> discountFilterOptions = [0, 30, 50, 70];
}

class FirestoreCollections {
  static const users = 'users';
  static const baskets = 'baskets';
  static const reservations = 'reservations';
  static const donations = 'donations';
  static const ngos = 'ngos';
}

enum UserRole { comercio, consumidor }

enum BasketType { visible, sorpresa }

enum BasketStatus { active, soldOut, expired, donated }

enum PaymentMethod { qrBancario, billeteraDigital, efectivoAlRecoger }

enum ReservationStatus { pending, confirmed, pickedUp, cancelled }

extension UserRoleX on UserRole {
  String get label => this == UserRole.comercio ? 'Comercio' : 'Consumidor';
  String get value => this == UserRole.comercio ? 'comercio' : 'consumidor';

  static UserRole fromValue(String v) =>
      v == 'comercio' ? UserRole.comercio : UserRole.consumidor;
}

extension BasketTypeX on BasketType {
  String get label =>
      this == BasketType.visible ? 'Visible' : 'Bolsa sorpresa';
  String get value => this == BasketType.visible ? 'visible' : 'sorpresa';

  static BasketType fromValue(String v) =>
      v == 'sorpresa' ? BasketType.sorpresa : BasketType.visible;
}

extension BasketStatusX on BasketStatus {
  String get value {
    switch (this) {
      case BasketStatus.active:
        return 'active';
      case BasketStatus.soldOut:
        return 'sold_out';
      case BasketStatus.expired:
        return 'expired';
      case BasketStatus.donated:
        return 'donated';
    }
  }

  static BasketStatus fromValue(String v) {
    switch (v) {
      case 'sold_out':
        return BasketStatus.soldOut;
      case 'expired':
        return BasketStatus.expired;
      case 'donated':
        return BasketStatus.donated;
      default:
        return BasketStatus.active;
    }
  }
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.qrBancario:
        return 'QR bancario';
      case PaymentMethod.billeteraDigital:
        return 'Billetera digital';
      case PaymentMethod.efectivoAlRecoger:
        return 'Efectivo al recoger';
    }
  }

  String get value {
    switch (this) {
      case PaymentMethod.qrBancario:
        return 'qr';
      case PaymentMethod.billeteraDigital:
        return 'wallet';
      case PaymentMethod.efectivoAlRecoger:
        return 'cash';
    }
  }
}

extension ReservationStatusX on ReservationStatus {
  String get value {
    switch (this) {
      case ReservationStatus.pending:
        return 'pending';
      case ReservationStatus.confirmed:
        return 'confirmed';
      case ReservationStatus.pickedUp:
        return 'picked_up';
      case ReservationStatus.cancelled:
        return 'cancelled';
    }
  }

  static ReservationStatus fromValue(String v) {
    switch (v) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'picked_up':
        return ReservationStatus.pickedUp;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.pending;
    }
  }
}
