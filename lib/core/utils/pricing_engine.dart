import '../../models/basket.dart';

/// Calcula el precio vigente de una canasta tipo "subasta holandesa":
/// el precio baja por franjas horarias definidas por el comercio,
/// sin bajar nunca del precio mínimo aceptable.
///
/// Corre en el cliente para reflejo en tiempo real en la UI. El mismo
/// algoritmo se replica en `functions/index.js` (Cloud Function programada)
/// para mantener `currentPrice` consistente en Firestore entre dispositivos.
class PricingEngine {
  /// Devuelve el precio vigente para [basket] evaluado en [now].
  static double currentPrice(Basket basket, DateTime now) {
    final tiers = [...basket.discountTiers]
      ..sort((a, b) => a.triggerTime.compareTo(b.triggerTime));

    double percentOff = 0;
    for (final tier in tiers) {
      final triggerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        tier.triggerTime.hour,
        tier.triggerTime.minute,
      );
      if (!now.isBefore(triggerDateTime)) {
        percentOff = tier.percentOff;
      }
    }

    final discounted = basket.originalPrice * (1 - percentOff / 100);
    return discounted < basket.minPrice ? basket.minPrice : discounted;
  }

  /// Porcentaje de descuento realmente aplicado en este momento
  /// (puede diferir del tier si el precio quedó topado por minPrice).
  static double currentDiscountPercent(Basket basket, DateTime now) {
    final price = currentPrice(basket, now);
    if (basket.originalPrice <= 0) return 0;
    return ((1 - price / basket.originalPrice) * 100).clamp(0, 100).toDouble();
  }

  /// Próxima franja de descuento que aún no se ha activado, o null si
  /// ya se activaron todas.
  static DiscountTier? nextTier(Basket basket, DateTime now) {
    final tiers = [...basket.discountTiers]
      ..sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
    for (final tier in tiers) {
      final triggerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        tier.triggerTime.hour,
        tier.triggerTime.minute,
      );
      if (now.isBefore(triggerDateTime)) return tier;
    }
    return null;
  }
}
