import 'package:geolocator/geolocator.dart';
import '../models/poi_model.dart';

class GeofenceService {
  /// Дефолтный радиус геозоны по умолчанию (в метрах)
  static const double defaultGeofenceRadiusMeters = 50.0;

  /// Вычисление дистанции до POI в метрах
  double getDistanceToPoi(Position userPosition, PoiModel poi) {
    return Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      poi.lat,
      poi.lng,
    );
  }

  /// Проверка, находится ли пользователь внутри геозоны POI
  bool isUserInGeofence(
    Position userPosition,
    PoiModel poi, {
    double radiusMeters = defaultGeofenceRadiusMeters,
  }) {
    final distance = getDistanceToPoi(userPosition, poi);
    return distance <= radiusMeters;
  }

  /// Поиск ближайшего POI с опциональным ограничением максимального расстояния
  PoiModel? findNearestPoi(
    Position userPosition,
    List<PoiModel> pois, {
    double maxRadiusMeters = double.infinity,
  }) {
    if (pois.isEmpty) return null;

    PoiModel? nearestPoi;
    double minDistance = maxRadiusMeters;

    for (final poi in pois) {
      final distance = getDistanceToPoi(userPosition, poi);

      if (distance < minDistance) {
        minDistance = distance;
        nearestPoi = poi;
      }
    }

    return nearestPoi;
  }

  /// Получение всех POI, попадающих в геозону пользователя
  List<PoiModel> findPoisInGeofence(
    Position userPosition,
    List<PoiModel> pois, {
    double radiusMeters = defaultGeofenceRadiusMeters,
  }) {
    return pois
        .where((poi) => isUserInGeofence(userPosition, poi, radiusMeters: radiusMeters))
        .toList();
  }
}
