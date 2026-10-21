/**
 * Precarga datos de ejemplo en Firebase (Auth + Firestore) usando el
 * caso numérico del PDF: panadería que produce 100 panes/día, costo
 * unitario Q1.50, precio normal Q4.00, le sobran 20 panes que vende con
 * 60% de descuento a Q1.60 c/u (comisión de plataforma 15%).
 *
 * Uso:
 *   1. En la consola de Firebase: Configuración del proyecto > Cuentas
 *      de servicio > Generar nueva clave privada. Guarda el archivo
 *      como seed/serviceAccountKey.json (NO lo subas a git).
 *   2. cd seed && npm install
 *   3. npm run seed
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();
const GeoPoint = admin.firestore.GeoPoint;
const Timestamp = admin.firestore.Timestamp;

const MERCHANT_EMAIL = 'panaderia@ultimatanda.gt';
const CONSUMER_EMAIL = 'consumidor@ultimatanda.gt';
const DEMO_PASSWORD = 'password123';

// Zona 10, Ciudad de Guatemala
const GT_CITY = new GeoPoint(14.5891, -90.514);

async function getOrCreateAuthUser(email, password, displayName) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    return auth.createUser({ email, password, displayName });
  }
}

function todayAt(hour, minute) {
  const d = new Date();
  d.setHours(hour, minute, 0, 0);
  return Timestamp.fromDate(d);
}

async function main() {
  console.log('Creando usuario comercio (panadería)...');
  const merchant = await getOrCreateAuthUser(MERCHANT_EMAIL, DEMO_PASSWORD, 'Panadería San José');
  await db.collection('users').doc(merchant.uid).set({
    email: MERCHANT_EMAIL,
    role: 'comercio',
    displayName: 'Panadería San José',
    phone: '',
    createdAt: Timestamp.now(),
    businessName: 'Panadería San José',
    businessAddress: '5a Avenida 10-25, Zona 10, Ciudad de Guatemala',
    businessLocation: GT_CITY,
    businessPhotoUrl: '',
    totalSavedQ: 0,
    totalKgRescued: 0,
    totalOrders: 0,
  }, { merge: true });

  console.log('Creando usuario consumidor de ejemplo...');
  const consumer = await getOrCreateAuthUser(CONSUMER_EMAIL, DEMO_PASSWORD, 'María López');
  await db.collection('users').doc(consumer.uid).set({
    email: CONSUMER_EMAIL,
    role: 'consumidor',
    displayName: 'María López',
    phone: '',
    createdAt: Timestamp.now(),
    businessName: '',
    businessAddress: '',
    businessLocation: null,
    businessPhotoUrl: '',
    totalSavedQ: 0,
    totalKgRescued: 0,
    totalOrders: 0,
  }, { merge: true });

  console.log('Publicando canasta de ejemplo (20 panes sobrantes)...');
  // Ejemplo del PDF: 100 panes/día, costo Q1.50, precio normal Q4.00,
  // sobran 20 panes -> 60% de descuento -> Q1.60 c/u.
  await db.collection('baskets').add({
    merchantId: merchant.uid,
    merchantName: 'Panadería San José',
    title: 'Bolsa de 5 panes del día',
    description: 'Pan francés y dulce horneado hoy, sobrante del día.',
    photoUrl: '',
    type: 'sorpresa',
    originalPrice: 4.0,
    minPrice: 1.6, // = 4.00 * (1 - 60%), tope real del ejemplo del PDF
    unitCost: 1.5,
    quantityTotal: 20,
    quantityAvailable: 20,
    pickupWindowStart: todayAt(19, 0),
    pickupWindowEnd: todayAt(21, 0),
    discountTiers: [
      { time: '17:00', percent: 30 },
      { time: '18:30', percent: 50 },
      { time: '19:30', percent: 70 }, // se topa en minPrice (Q1.60)
    ],
    location: GT_CITY,
    address: '5a Avenida 10-25, Zona 10, Ciudad de Guatemala',
    status: 'active',
    createdAt: Timestamp.now(),
  });

  console.log('Creando banco de alimentos de ejemplo...');
  await db.collection('ngos').add({
    name: 'Banco de Alimentos Guatemala',
    address: '12 Calle 3-45, Zona 1, Ciudad de Guatemala',
    location: GT_CITY,
    contact: 'contacto@bancodealimentos.gt',
  });

  console.log('\nListo. Cuentas de prueba:');
  console.log(`  Comercio:   ${MERCHANT_EMAIL} / ${DEMO_PASSWORD}`);
  console.log(`  Consumidor: ${CONSUMER_EMAIL} / ${DEMO_PASSWORD}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
