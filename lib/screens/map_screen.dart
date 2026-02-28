import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/poi_model.dart';
import '../services/poi_repository.dart';
import '../services/geofence_service.dart';
import '../services/audio_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _eventChannel = EventChannel('com.example.do_an/location_stream');

  // Tọa độ khu vực trung tâm phố ốc Vĩnh Khánh
  LatLng _userPos = const LatLng(10.7583, 106.7065);
  POI? _activePOI;
  final Set<String> _playedHistory = {};
  final MapController _mapController = MapController();
  StreamSubscription? _locationSubscription;

  late GeofenceService _geofenceService;
  final AudioService _audioService = AudioService();
  late final List<POI> _poiList;

  @override
  void initState() {
    super.initState();
    _poiList = POIRepository.getTourPoints();
    _geofenceService = GeofenceService(
      _poiList,
      cooldown: const Duration(minutes: 5),
    );
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

  void _processLocationUpdate(LatLng newLoc) {
    if (!mounted) return;

    double distanceMoved = const Distance().as(LengthUnit.Meter, _userPos, newLoc);

    if (distanceMoved > 2 || _activePOI == null) {
      setState(() {
        _userPos = newLoc;
      });

      POI? nearbyPOI = _geofenceService.checkPOIs(newLoc);

      if (nearbyPOI != null) {
        if (nearbyPOI.id != _activePOI?.id && !_playedHistory.contains(nearbyPOI.id)) {
          setState(() {
            _activePOI = nearbyPOI;
          });
          _audioService.playPOI(nearbyPOI);
          _playedHistory.add(nearbyPOI.id);
        }
      } else {
        if (_activePOI != null) {
          setState(() {
            _activePOI = null;
          });
          _audioService.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vĩnh Khánh Food Tour", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _playedHistory.clear()),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. LỚP BẢN ĐỒ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPos,
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.do_an',
                maxZoom: 19,
              ),

              // BÁN KÍNH GEOFENCE
              CircleLayer(
                circles: _poiList.map((poi) => CircleMarker(
                  point: poi.location,
                  radius: poi.radius.toDouble(),
                  useRadiusInMeter: true,
                  color: _activePOI?.id == poi.id 
                      ? Colors.orange.withValues(alpha: 0.3) 
                      : Colors.blue..withValues(alpha: 0.1),
                  borderColor: _activePOI?.id == poi.id ? Colors.orange : Colors.blue,
                  borderStrokeWidth: 2,
                )).toList(),
              ),

              // CÁC ĐIỂM MARKER
              MarkerLayer(
                markers: [
                  // Vị trí người dùng (Chấm xanh)
                  Marker(
                    point: _userPos,
                    width: 60,
                    height: 60,
                    child: _buildUserMarker(),
                  ),
                  
                  // Danh sách các quán ốc
                  ..._poiList.map((poi) {
                    final bool isActive = _activePOI?.id == poi.id;
                    return Marker(
                      point: poi.location,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showPOIDetail(poi),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.restaurant,
                            color: isActive ? Colors.orange : Colors.grey,
                            size: isActive ? 40 : 30,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. NÚT CHỨC NĂNG GÓC TRÊN (Dịch, Định vị)
          Positioned(
            top: 20,
            right: 15,
            child: Column(
              children: [
                _buildFloatingButton(Icons.translate, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chuyển đổi ngôn ngữ...")),
                  );
                }),
                const SizedBox(height: 10),
                _buildFloatingButton(Icons.gps_fixed, () {
                  _mapController.move(_userPos, 18.0);
                }),
              ],
            ),
          ),

          // 3. THẺ THUYẾT MINH (Khi đi vào vùng Geofence)
          if (_activePOI != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildActivePOICard(),
            ),
        ],
      ),
      
      // NÚT ĐỊNH VỊ CHÍNH
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => _mapController.move(_userPos, 18),
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }

  // WIDGET HỖ TRỢ
  Widget _buildUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(color: Colors.blue..withValues(alpha: 0.2), shape: BoxShape.circle),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivePOICard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _activePOI!.imageAsset != null 
                ? Image.asset('assets/images/${_activePOI!.imageAsset}', width: 60, height: 60, fit: BoxFit.cover)
                : Container(width: 60, height: 60, color: Colors.grey[200]),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("ĐANG THUYẾT MINH", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(_activePOI!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(_activePOI!.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.volume_up, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 45,
      height: 45,
      child: FloatingActionButton(
        heroTag: null,
        elevation: 4,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: onPressed,
        child: Icon(icon, size: 20),
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
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              if (poi.imageAsset != null)
                Image.asset('assets/images/${poi.imageAsset}', fit: BoxFit.cover, width: double.infinity, height: 250)
              else 
                Container(height: 250, color: Colors.grey[300], child: const Icon(Icons.image, size: 50)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poi.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(poi.description),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _launchURL('https://www.google.com/maps/search/?api=1&query=${poi.location.latitude},${poi.location.longitude}'),
                      icon: const Icon(Icons.directions),
                      label: const Text("Chỉ đường đến quán"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Lỗi mở link: $url');
    }
  }
}