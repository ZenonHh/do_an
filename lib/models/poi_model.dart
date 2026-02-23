import 'package:latlong2/latlong.dart';

enum NarrationType { tts, audio }

class POI {
  final String id;
  final String name;
  final LatLng location;
  final double radius;
  final String description;
  final String? imageUrl;
  final String? mapLink; // Link Google Maps
  final int priority;
  final NarrationType narrationType;
  final String content;

  POI({
    required this.id,
    required this.name,
    required this.location,
    required this.radius,
    this.description = '',
    this.imageUrl,
    this.mapLink,
    this.priority = 0,
    this.narrationType = NarrationType.tts,
    required this.content,
  });

  double distanceTo(LatLng userLocation) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, location, userLocation);
  }
}
