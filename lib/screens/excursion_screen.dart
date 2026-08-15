import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class ExcursionScreen extends StatefulWidget {
  final bool? startInMapView;
  final bool? isMapView;
  final Map<String, dynamic>? poi;

  const ExcursionScreen({
    Key? key,
    this.startInMapView,
    this.isMapView,
    this.poi,
  }) : super(key: key);

  @override
  State<ExcursionScreen> createState() => _ExcursionScreenState();
}

class _ExcursionScreenState extends State<ExcursionScreen> {
  final MapController _mapController = MapController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  LatLng _currentLocation = const LatLng(59.2205, 39.8915); // Вологда
  bool _isLoading = false;
  String _guideResponseText = "Нажмите 'Спросить гида' или подойдите к достопримечательности.";
  String _selectedGuide = "alexander";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation, 16.0);
      }
    } catch (e) {
      debugPrint("Ошибка геолокации: $e");
    }
  }

  Future<void> _requestAiStory() async {
    setState(() {
      _isLoading = true;
      _guideResponseText = "Гид Yandex AI формирует рассказ...";
    });

    try {
      final response = await ApiService.generateGuideStory(
        lat: _currentLocation.latitude,
        lng: _currentLocation.longitude,
        guideId: _selectedGuide,
      );

      final text = response['text'] ?? response['answer'] ?? response['description'] ?? "Рассказ готов.";
      final rawAudioUrl = response['audio_url'] ?? response['audio'] ?? response['voice_url'];
      final formattedAudioUrl = ApiService.formatAudioUrl(rawAudioUrl?.toString());

      setState(() {
        _guideResponseText = text;
      });

      if (formattedAudioUrl != null && formattedAudioUrl.isNotEmpty) {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(formattedAudioUrl));
      }
    } catch (e) {
      setState(() {
        _guideResponseText = "Ошибка загрузки: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Экскурсия GID'),
        actions: [
          DropdownButton<String>(
            value: _selectedGuide,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'alexander', child: Text('Александр')),
              DropdownMenuItem(value: 'anna', child: Text('Анна')),
              DropdownMenuItem(value: 'mikhail', child: Text('Михаил')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedGuide = val);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.gid_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            bottom: 20.0 + bottomPadding,
            left: 16.0,
            right: 16.0,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _guideResponseText,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _requestAiStory,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.record_voice_over),
                      label: Text(_isLoading ? "Думает..." : "Спросить гида (Yandex AI)"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
