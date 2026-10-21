# Última Tanda

Prototipo funcional de un marketplace de dos lados (comercios ↔ consumidores)
para vender comida próxima a vencer o sobrante del día a precio reducido,
con precio dinámico decreciente ("subasta holandesa") por franjas horarias.

Stack: **Flutter + Firebase (Auth, Firestore, Storage) + Google Maps SDK +
Provider**.

---

## 0. Estado de este repo

Este repo trae **todo el código Dart** (`lib/`), **modelos de datos**,
**reglas de Firestore/Storage**, un **script de seed** y una **Cloud
Function opcional**. Lo que NO trae (porque requiere el SDK de Flutter
instalado y un proyecto de Firebase real, cosas que no existen en esta
máquina) son las carpetas nativas `android/` e `ios/` ni las credenciales
de Firebase/Google Maps. Los pasos de abajo generan eso en tu máquina en
~15 minutos.

---

## 1. Instalar herramientas (una sola vez)

1. **Flutter SDK**: sigue https://docs.flutter.dev/get-started/install
   (elige Windows). Verifica con:
   ```
   flutter doctor
   ```
   Resuelve lo que `flutter doctor` marque en rojo (Android toolchain,
   licencias de Android SDK con `flutter doctor --android-licenses`).
2. **Android Studio** (para el SDK de Android y el emulador). Desde
   Android Studio > More Actions > Virtual Device Manager, crea un AVD
   (ej. Pixel 7, API 34) **con Google Play** (lo necesitas para Google
   Maps).
3. **Node.js** (v18+) — solo para el script de seed y las Cloud Functions
   opcionales.
4. Cuenta de **Firebase** (console.firebase.google.com) y una **API key
   de Google Maps** (console.cloud.google.com, con "Maps SDK for
   Android" habilitado).

---

## 2. Generar las carpetas nativas (android/ios)

Desde esta carpeta (`ultima_tanda/`):

```
flutter create --org com.ultimatanda --platforms=android,ios .
```

`flutter create .` sobre un proyecto existente **no sobrescribe**
`pubspec.yaml` ni `lib/` (ya existen) — solo genera lo que falta:
`android/`, `ios/`, `web/`, etc. Si te pregunta por algún archivo
puntual, acepta el valor por defecto.

Luego instala las dependencias:

```
flutter pub get
```

### Requisitos mínimos de Android (google_maps_flutter)

Abre `android/app/build.gradle` y confirma:

```gradle
android {
    defaultConfig {
        minSdkVersion 21   // google_maps_flutter requiere >= 21
        ...
    }
}
```

---

## 3. Conectar tu propio proyecto de Firebase

1. Crea un proyecto en https://console.firebase.google.com.
2. En **Authentication > Sign-in method**, habilita **Correo
   electrónico/contraseña**.
3. En **Firestore Database**, crea la base (modo producción — las reglas
   ya vienen en `firestore/firestore.rules`).
4. En **Storage**, actívalo (reglas en `storage.rules`).
5. Instala la CLI de Firebase y FlutterFire, e inicia sesión:
   ```
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```
6. Desde `ultima_tanda/`, conecta el proyecto (esto **reemplaza**
   `lib/firebase_options.dart` con tus credenciales reales):
   ```
   flutterfire configure --platforms=android,ios
   ```
   Selecciona tu proyecto de Firebase y ambas plataformas. No necesitas
   tocar `android/app/build.gradle` para esto: `firebase_options.dart`
   inicializa Firebase directamente en Dart.
7. Despliega las reglas de Firestore/Storage:
   ```
   firebase use --add          # selecciona tu proyecto
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

---

## 4. Google Maps SDK (Android)

Abre `android/app/src/main/AndroidManifest.xml` y dentro de la etiqueta
`<application ...>` agrega:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_DE_GOOGLE_MAPS" />
```

Y dentro de `<manifest ...>` (fuera de `<application>`) confirma que
estén los permisos de ubicación (Flutter suele agregarlos automáticamente
al detectar `geolocator`; si no, agrégalos):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 5. Precargar datos de ejemplo (seed)

Usa el ejemplo numérico del PDF: panadería con costo unitario Q1.50,
precio normal Q4.00, 20 panes sobrantes con 60% de descuento (Q1.60),
comisión de plataforma 15%.

1. En la consola de Firebase: **Configuración del proyecto > Cuentas de
   servicio > Generar nueva clave privada**. Guarda el JSON como
   `seed/serviceAccountKey.json` (ya está en `.gitignore`, no lo subas a
   git).
2. ```
   cd seed
   npm install
   npm run seed
   ```
3. Esto crea dos cuentas de prueba (correo / contraseña):
   - Comercio: `panaderia@ultimatanda.gt` / `password123`
   - Consumidor: `consumidor@ultimatanda.gt` / `password123`

   Y publica la canasta de ejemplo + un banco de alimentos para probar
   "rescate solidario".

---

## 6. Ejecutar la app

### En emulador Android

1. Abre el AVD: Android Studio > Device Manager > ▶ en tu emulador (o
   `flutter emulators --launch <id>`).
2. Desde `ultima_tanda/`:
   ```
   flutter run
   ```
3. El emulador de Android normalmente reporta una ubicación fija (o
   ninguna) — puedes fijarla en **Extended controls (⋮) > Location** del
   emulador para que quede cerca de la canasta de ejemplo (Zona 10,
   Ciudad de Guatemala: `14.5891, -90.5140`). Si el GPS no está
   disponible, la app cae automáticamente a esa ubicación por defecto.

### En un celular físico (USB)

1. En el teléfono: **Ajustes > Acerca del teléfono**, toca 7 veces
   "Número de compilación" para activar Opciones de desarrollador.
2. **Ajustes > Opciones de desarrollador**, activa **Depuración USB**.
3. Conecta el cable USB a la PC. Acepta el diálogo "¿Permitir depuración
   USB?" que aparece en el teléfono.
4. Verifica que se detecta:
   ```
   flutter devices
   ```
5. Ejecuta:
   ```
   flutter run
   ```
   Si `flutter devices` no lo lista, instala/actualiza los drivers USB
   del fabricante o prueba otro cable (algunos son solo de carga).

---

## 7. Probar el flujo

1. Regístrate como **Comercio** → publica una canasta (o usa la
   precargada por el seed).
2. Cierra sesión, regístrate como **Consumidor** (o usa
   `consumidor@ultimatanda.gt` / `password123`).
3. En "Ofertas cerca de ti", verás la canasta con su precio vigente
   bajando según las franjas horarias configuradas. Resérvala, elige un
   método de pago (simulado) y obtén tu **código de recogida**.
4. En "Mis reservas" verás el historial y tu índice de impacto (Q
   ahorrados, kg rescatados).
5. Desde el panel del comercio, puedes marcar una canasta como
   **rescate solidario** para donarla a un banco de alimentos en vez de
   venderla.

---

## Estructura del proyecto

```
lib/
  core/               # constantes, tema, motor de precio dinámico
  models/             # AppUser, Basket, Reservation, Donation (Firestore)
  services/           # Auth, Firestore, Storage, ubicación
  providers/          # estado (Provider): auth, ofertas, reservas, comercio
  screens/
    auth/             # login / registro con selección de rol
    consumer/         # mapa/lista, detalle+pago, confirmación, historial
    merchant/         # publicar canasta, panel de ofertas/ingresos
    shared/           # rescate solidario (donación a banco de alimentos)
  widgets/            # tarjetas de oferta, precio en vivo, stat tiles
firestore/            # reglas de seguridad + índices
storage.rules
functions/            # Cloud Function opcional (recalcula precio server-side)
seed/                 # script de datos de ejemplo (Node + firebase-admin)
```

### Modelo de datos (Firestore)

- `users/{uid}`: perfil, rol (`comercio`/`consumidor`), datos del negocio
  o índice de impacto acumulado del consumidor.
- `baskets/{id}`: canasta publicada — precio original/mínimo, cantidad,
  ventana de recogida, `discountTiers` (franjas horarias de descuento),
  ubicación (`GeoPoint`), estado.
- `reservations/{id}`: reserva de un consumidor sobre una canasta —
  precio pagado, comisión de plataforma, código de recogida, estado.
- `donations/{id}`: donación de una canasta completa a un `ngos/{id}`.

### Regla de precio dinámico

Ver `lib/core/utils/pricing_engine.dart`. Dado el precio original, el
precio mínimo y las franjas horarias (`{time, percent}`), calcula el
precio vigente para cualquier instante, sin bajar nunca del mínimo. Corre
en el cliente (se recalcula cada 20-30s en las pantallas relevantes) y,
opcionalmente, en la Cloud Function programada de `functions/index.js`.

---

## Notas del prototipo

- El pago es **simulado** (QR bancario / billetera digital / efectivo al
  recoger no procesan ningún cobro real).
- El filtro de distancia usa fórmula de Haversine en el cliente sobre las
  canastas activas (suficiente para un prototipo; a escala conviene
  geohashing o una extensión de Firestore para consultas geoespaciales).
- No se implementó recuperación de contraseña ni verificación de correo
  — es fácil de añadir con `firebase_auth` si se necesita después.
