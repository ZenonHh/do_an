import 'dart:async';
import 'package:do_an/services/poi_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/poi_model.dart';
import '../services/geofence_service.dart';
import '../services/audio_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _eventChannel = EventChannel('com.example.do_an/location_stream');

  LatLng _userPos = const LatLng(21.0285, 105.8542); // Default to Ho Guom
  POI? _activePOI;
  final MapController _mapController = MapController();
  StreamSubscription? _locationSubscription;

  late GeofenceService _geofenceService;
  final AudioService _audioService = AudioService();
  late final List<POI> _poiList;

  @override
  void initState() {
    super.initState();
    // Lấy dữ liệu từ Repository thay vì hardcode
    _poiList = POIRepository.getTourPoints();
    _geofenceService = GeofenceService(_poiList);
    _startListeningLocation();
  }

  void _startListeningLocation() {
    _locationSubscription = _eventChannel.receiveBroadcastStream().listen((data) {
      if (data is Map) {
        final double lat = data['lat'];
        final double lng = data['lng'];
        _processLocationUpdate(LatLng(lat, lng));
      }
    }, onError: (err) {
      debugPrint("Lỗi nhận GPS: $err");
    });
  }

  void _processLocationUpdate(LatLng userLoc) {
    if (!mounted) return;

    setState(() {
      _userPos = userLoc;
    });

    POI? nearbyPOI = _geofenceService.checkPOIs(userLoc);

    if (nearbyPOI != null && nearbyPOI.id != _activePOI?.id) {
      setState(() {
        _activePOI = nearbyPOI;
      });
      _audioService.playPOI(nearbyPOI);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Tour Guide"),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userPos,
          initialZoom: 15.0,
          onMapReady: () => _mapController.move(_userPos, 15.0)
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.do_an',
          ),
          CircleLayer(
            circles: _poiList.map((poi) => CircleMarker(
              point: poi.location,
              radius: poi.radius,
              useRadiusInMeter: true,
              color: Colors.green.withOpacity(0.15),
              borderColor: Colors.green,
              borderStrokeWidth: 1,
            )).toList(),
          ),
          MarkerLayer(
            markers: [
              Marker(point: _userPos, child: const Icon(Icons.navigation, color: Colors.blue, size: 35)),
              ..._poiList.map((poi) => Marker(
                point: poi.location,
                child: GestureDetector(
                  onTap: () => _showPOIDetail(poi),
                  child: Icon(
                    Icons.location_on,
                    color: _activePOI?.id == poi.id ? Colors.red : Colors.orange,
                    size: 30,
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  void _showPOIDetail(POI poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (poi.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(poi.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: 200),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poi.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(poi.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _launchURL(poi.mapLink),
                      icon: const Icon(Icons.directions),
                      label: const Text("Chỉ đường (Google Maps)"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 16)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }
}
