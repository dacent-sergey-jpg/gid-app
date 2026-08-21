import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class ExcursionScreen extends StatefulWidget {
  final double? lat;
  final double? lng;
  final String? guideId;
  final bool? startInMapView;

  const ExcursionScreen({
    Key? key,
    this.lat,
    this.lng,
    this.guideId,
    this.startInMapView,
  }) : super(key: key);

  @override
  State<ExcursionScreen> createState() => _ExcursionScreenState();
}

class _ExcursionScreenState extends State<ExcursionScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Загрузка экскурсии...';
  String? _audioUrl;

  late double _currentLat;
  late double _currentLng;
  late String _currentGuideId;

  @override
  void initState() {
    super.initState();
    // Координаты Вологды по умолчанию, если параметры не переданы
    _currentLat = widget.lat ?? 59.2205;
    _currentLng = widget.lng ?? 39.8915;
    _currentGuideId = widget.guideId ?? 'VOLOGDA_GUIDE';
    _startExcursion();
  }

  Future<void> _startExcursion() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Подключение к гиду (сервер просыпается)...';
    });

    try {
      final response = await ApiService.askGuide(
        lat: _currentLat,
        lng: _currentLng,
        guideId: _currentGuideId,
        userQuestion: 'Начни экскурсию по текущим координатам',
      );

      setState(() {
        _isLoading = false;
        _statusMessage = response['text_response'] ?? response['answer'] ?? 'Экскурсия начата';
        _audioUrl = ApiService.formatAudioUrl(response['audio_url']);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка при попытке начать экскурсию: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLatLng = LatLng(_currentLat, _currentLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Интерактивная экскурсия'),
      ),
      body: Column(
        children: [
          // Полноценная интерактивная карта OpenStreetMap
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: currentLatLng,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.gid_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Панель состояния экскурсии
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.record_voice_over),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Гид: $_currentGuideId',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                ],
                Text(_statusMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
