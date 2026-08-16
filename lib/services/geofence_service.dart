import 'package:geolocator/geolocator.dart';
import '../models/poi_model.dart';

class GeofenceService {
  static const double geofenceRadiusMeters = 50.0;

  bool isUserInGeofence(Position userPosition, PoiModel poi) {
    double distanceInMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      poi.lat,
      poi.lng,
    );

    return distanceInMeters <= geofenceRadiusMeters;
  }

  PoiModel? findNearestPoi(Position userPosition, List<PoiModel> pois) {
    if (pois.isEmpty) return null;

    PoiModel? nearestPoi;
    double minDistance = double.infinity;

    for (var poi in pois) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        poi.lat,
        poi.lng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestPoi = poi;
      }
    }

    return nearestPoi;
  }
}
