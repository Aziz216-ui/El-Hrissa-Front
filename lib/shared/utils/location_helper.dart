import 'package:geolocator/geolocator.dart';
import '../../core/services/profile_service.dart';

enum LocationResult { ok, denied, deniedForever, serviceOff, failed }

/// Coordonnées par défaut (centre de Tunis), proposées si le GPS est refusé.
const double defaultLatitude = 36.8065;
const double defaultLongitude = 10.1815;

class LocationHelper {
  /// Demande la permission, lit la position et l'envoie au backend.
  static Future<LocationResult> updateFromDevice() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocationResult.serviceOff;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) return LocationResult.denied;
      if (permission == LocationPermission.deniedForever) return LocationResult.deniedForever;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)),
      );
      await ProfileService().updateLocation(pos.latitude, pos.longitude);
      return LocationResult.ok;
    } catch (_) {
      return LocationResult.failed;
    }
  }

  /// Position choisie manuellement (centre de Tunis).
  static Future<void> useDefaultCity() => ProfileService().updateLocation(defaultLatitude, defaultLongitude);

  static String describe(LocationResult r) {
    switch (r) {
      case LocationResult.ok:
        return 'Position mise à jour';
      case LocationResult.denied:
        return 'Autorisation de localisation refusée';
      case LocationResult.deniedForever:
        return 'Localisation bloquée : activez-la dans les réglages de votre appareil';
      case LocationResult.serviceOff:
        return 'Le service de localisation est désactivé';
      case LocationResult.failed:
        return 'Impossible de déterminer votre position';
    }
  }
}
