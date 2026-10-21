import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<GeoPoint> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El GPS está desactivado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    return GeoPoint(position.latitude, position.longitude);
  }

  /// Ubicación por defecto: Ciudad de Guatemala (zona 10), usada cuando
  /// no se puede obtener el GPS (ej. emulador sin ubicación configurada).
  static GeoPoint get guatemalaCityDefault => const GeoPoint(14.5891, -90.5140);
}
