import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/poi_model.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _userPos = const LatLng(21.0285, 105.8542);
  POI? _currentPOI;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  // Dữ liệu mẫu (Sau này có thể lấy từ Database hoặc API)
  final List<POI> _poiList = [
    POI(id: '1', name: "Hồ Gươm", location: const LatLng(21.0285, 105.8542), radius: 100),
    POI(id: '2', name: "Nhà Thờ Lớn", location: const LatLng(21.0288, 105.8490), radius: 60),
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() async {
    bool hasPermission = await LocationService.handleLocationPermission();
    if (!hasPermission) return;

    _positionStream = LocationService.getPositionStream().listen((pos) {
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      _checkGeofence(userLatLng);
    });
  }

  void _checkGeofence(LatLng userLoc) {
    POI? found;
    for (var poi in _poiList) {
      double dist = const Distance().as(LengthUnit.Meter, userLoc, poi.location);
      if (dist <= poi.radius) {
        found = poi;
        break;
      }
    }
    setState(() {
      _userPos = userLoc;
      _currentPOI = found;
    });
    _mapController.move(userLoc, 16.0);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Tour Guide")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _userPos, initialZoom: 16.0),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
          MarkerLayer(
            markers: [
              Marker(point: _userPos, child: const Icon(Icons.navigation, color: Colors.blue, size: 40)),
              ..._poiList.map((poi) => Marker(
                point: poi.location,
                child: Icon(Icons.location_on, color: _currentPOI?.id == poi.id ? Colors.red : Colors.grey),
              )),
            ],
          ),
        ],
      ),
    );
  }

  
}