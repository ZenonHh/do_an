import 'package:latlong2/latlong.dart';
import '../models/poi_model.dart';

class GeofenceService {
  final List<POI> _pois;
  final Map<String, DateTime> _history = {};
  final Duration cooldown;

  GeofenceService(this._pois, {this.cooldown = const Duration(minutes: 5)});

  POI? checkPOIs(LatLng userLocation) {
    POI? bestPOI;
    double minDistance = double.infinity;

    for (var poi in _pois) {
      double distance = poi.distanceTo(userLocation);

      if (distance <= poi.radius) {
        // Check cooldown
        if (_history.containsKey(poi.id)) {
          if (DateTime.now().difference(_history[poi.id]!) < cooldown) {
            continue;
          }
        }

        // Logic: Highest priority first, then closest distance
        if (bestPOI == null ||
            poi.priority > bestPOI.priority ||
            (poi.priority == bestPOI.priority && distance < minDistance)) {
          bestPOI = poi;
          minDistance = distance;
        }
      }
    }

    if (bestPOI != null) {
      _history[bestPOI.id] = DateTime.now();
    }

    return bestPOI;
  }

  void resetHistory() {
    _history.clear();
  }
}
