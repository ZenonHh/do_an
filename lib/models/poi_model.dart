import 'package:latlong2/latlong.dart';

class POI {
  final String id;
  final String name;
  final LatLng location;
  final double radius;
  final String description;

  POI({
    required this.id,
    required this.name,
    required this.location,
    required this.radius,
    this.description = '',
  });
}