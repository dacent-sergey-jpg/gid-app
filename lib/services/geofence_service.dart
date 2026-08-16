import 'package:geolocator/geolocator.dart';
import '../models/poi_model.dart';

class GeofenceService {
  static const double geofenceRadiusMeters = 50.0;

  /// Проверяет, находится ли пользователь в геозоне объекта
  bool isUserInGeofence(Position userPosition, PoiModel poi) {
    double distanceInMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      poi.latitude,
      poi.longitude, // Использовано longitude вместо lon
    );

    return distanceInMeters <= geofenceRadiusMeters;
  }

  /// Находит ближайшую к пользователю точку из списка
  PoiModel? findNearestPoi(Position userPosition, List<PoiModel> pois) {
    if (pois.isEmpty) return null;

    PoiModel? nearestPoi;
    double minDistance = double.infinity;

    for (var poi in pois) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        poi.latitude,
        poi.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestPoi = poi;
      }
    }

    return nearestPoi;
  }
}
