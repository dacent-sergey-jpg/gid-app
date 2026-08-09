import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class GeofenceService {
  final Set<int> _triggeredPoiIds = {};
  final double triggerRadiusMeters;

  GeofenceService({this.triggerRadiusMeters = 30.0});

  /// Проверяет списки объектов и возвращает тот, к которому подошел пользователь
  PoiModel? checkProximity({
    required double userLat,
    required double userLon,
    required List<PoiModel> poiList,
  }) {
    for (final poi in poiList) {
      if (_triggeredPoiIds.contains(poi.id)) continue;

      final distance = Geolocator.distanceBetween(
        userLat,
        userLon,
        poi.lat,
        poi.lon,
      );

      if (distance <= triggerRadiusMeters) {
        _triggeredPoiIds.add(poi.id);
        return poi;
      }
    }
    return null;
  }

  void resetTriggers() {
    _triggeredPoiIds.clear();
  }
}
