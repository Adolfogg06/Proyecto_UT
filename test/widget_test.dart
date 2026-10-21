import 'package:flutter_test/flutter_test.dart';
import 'package:ultima_tanda/core/utils/pricing_engine.dart';
import 'package:ultima_tanda/models/basket.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('PricingEngine', () {
    Basket buildBasket() {
      final now = DateTime.now();
      return Basket(
        id: 'b1',
        merchantId: 'm1',
        merchantName: 'Panadería San José',
        title: 'Bolsa de panes',
        originalPrice: 4.0,
        minPrice: 1.6,
        quantityTotal: 20,
        quantityAvailable: 20,
        pickupWindowStart: now,
        pickupWindowEnd: now.add(const Duration(hours: 2)),
        discountTiers: [
          DiscountTier(triggerTime: DateTime(now.year, now.month, now.day, 17, 0), percentOff: 30),
          DiscountTier(triggerTime: DateTime(now.year, now.month, now.day, 18, 30), percentOff: 50),
          DiscountTier(triggerTime: DateTime(now.year, now.month, now.day, 19, 30), percentOff: 70),
        ],
        location: const GeoPoint(14.5891, -90.5140),
      );
    }

    test('no aplica descuento antes de la primera franja', () {
      final basket = buildBasket();
      final before = DateTime(basket.pickupWindowStart.year, basket.pickupWindowStart.month,
          basket.pickupWindowStart.day, 10, 0);
      expect(PricingEngine.currentPrice(basket, before), 4.0);
    });

    test('aplica el descuento de la franja ya activada', () {
      final basket = buildBasket();
      final at1745 = DateTime(basket.pickupWindowStart.year, basket.pickupWindowStart.month,
          basket.pickupWindowStart.day, 17, 45);
      expect(PricingEngine.currentPrice(basket, at1745), closeTo(2.8, 0.001)); // 4.00 * 0.70
    });

    test('nunca baja del precio mínimo aunque el tier lo indique', () {
      final basket = buildBasket();
      final at2000 = DateTime(basket.pickupWindowStart.year, basket.pickupWindowStart.month,
          basket.pickupWindowStart.day, 20, 0);
      // -70% daría 1.20, pero el mínimo es 1.60
      expect(PricingEngine.currentPrice(basket, at2000), 1.6);
    });
  });
}
