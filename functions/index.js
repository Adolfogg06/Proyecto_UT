/**
 * Cloud Function OPCIONAL: recalcula `currentPrice` de cada canasta activa
 * cada 5 minutos y lo guarda en Firestore, para que la baja de precio por
 * franjas horarias quede reflejada aunque el cliente no esté abierto.
 *
 * La app Flutter YA calcula el precio en tiempo real en el cliente
 * (ver lib/core/utils/pricing_engine.dart) — esta función es un respaldo
 * para mantener el dato consistente en el propio documento de Firestore
 * (útil para reportes, notificaciones push futuras, etc.). No es
 * obligatoria para que el prototipo funcione.
 *
 * Despliegue:
 *   cd functions && npm install
 *   firebase deploy --only functions
 */
const { onSchedule } = require('firebase-functions/scheduler');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

function currentPriceFor(basket, now) {
  const tiers = [...(basket.discountTiers || [])].sort((a, b) =>
    a.time.localeCompare(b.time)
  );

  let percentOff = 0;
  for (const tier of tiers) {
    const [h, m] = tier.time.split(':').map(Number);
    const trigger = new Date(now);
    trigger.setHours(h, m, 0, 0);
    if (now >= trigger) percentOff = tier.percent;
  }

  const discounted = basket.originalPrice * (1 - percentOff / 100);
  return Math.max(discounted, basket.minPrice);
}

exports.recalculateActiveBasketPrices = onSchedule('every 5 minutes', async () => {
  const now = new Date();
  const snap = await db.collection('baskets').where('status', '==', 'active').get();

  const batch = db.batch();
  snap.forEach((doc) => {
    const basket = doc.data();
    const price = currentPriceFor(basket, now);
    batch.update(doc.ref, { currentPrice: price });
  });

  await batch.commit();
  console.log(`Precios recalculados para ${snap.size} canastas activas`);
});
