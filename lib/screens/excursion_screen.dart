import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/poi_model.dart';
import '../services/api_service.dart';
import '../services/geofence_service.dart';
import '../widgets/audio_player_sheet.dart';

class ExcursionScreen extends StatefulWidget {
  final bool startInMapView;

  const ExcursionScreen({Key? key, this.startInMapView = false}) : super(key: key);

  @override
  State<ExcursionScreen> createState() => _ExcursionScreenState();
}

class _ExcursionScreenState extends State<ExcursionScreen> {
  final GeofenceService _geofenceService = GeofenceService(triggerRadiusMeters: 35.0);
  final AudioPlayer _audioPlayer = AudioPlayer();

  Position? _currentPosition;
  List<PoiModel> _poiList = [];
  PoiModel? _nearestPoi;
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;

  // Вологдa по умолчанию
  final LatLng _defaultCenter = const LatLng(59.224167, 39.883889);

  @override
  void initState() {
    super.initState();
    _initExcursion();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initExcursion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = pos);
      _startTracking();
    }

    await _fetchPois();
  }

  Future<void> _fetchPois() async {
    final lat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final lon = _currentPosition?.longitude ?? _defaultCenter.longitude;

    try {
      final pois = await ApiService.fetchNearbyPois(lat: lat, lon: lon);
      setState(() {
        _poiList = pois;
        if (pois.isNotEmpty) {
          _nearestPoi = pois.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() => _currentPosition = position);

      // Проверка на вхождение в геозону (< 35 метров)
      final triggeredPoi = _geofenceService.checkProximity(
        userLat: position.latitude,
        userLon: position.longitude,
        poiList: _poiList,
      );

      if (triggeredPoi != null) {
        _openAudioSheet(triggeredPoi);
      }
    });
  }

  void _openAudioSheet(PoiModel poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudioPlayerSheet(
        poi: poi,
        audioPlayer: _audioPlayer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Экскурсия', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Интерактивная Карта
                FlutterMap(
                  options: MapOptions(
                    initialCenter: userLatLng,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.gid_app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Геолокация пользователя
                        Marker(
                          point: userLatLng,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
                        ),
                        // Маркеры достопримечательностей
                        ..._poiList.map((poi) => Marker(
                              point: LatLng(poi.lat, poi.lon),
                              width: 45,
                              height: 45,
                              child: GestureDetector(
                                onTap: () => _openAudioSheet(poi),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                                  ),
                                  child: const Icon(Icons.account_balance, color: Color(0xFF6C5CE7), size: 26),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),

                // Панель статуса с информацией про ближайший объект (Раздел 4 ТЗ)
                if (_nearestPoi != null)
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.near_me_outlined, color: Color(0xFF6C5CE7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Вы рядом с: ${_nearestPoi!.title}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Расстояние: ${_nearestPoi!.distanceMeters.toStringAsFixed(0)} м',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Подойдите ближе (< 30 м), чтобы гид начал рассказ.',
                            style: TextStyle(color: Color(0xFF6C5CE7), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _openAudioSheet(_nearestPoi!),
                              child: const Text('Слушать сейчас', style: TextStyle(color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
              ],
            ),
    );
  }
}
