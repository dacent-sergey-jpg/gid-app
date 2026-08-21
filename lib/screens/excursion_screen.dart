import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class ExcursionScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final String guideId;

  const ExcursionScreen({
    Key? key,
    required this.lat,
    required this.lng,
    this.guideId = 'VOLOGDA_GUIDE',
  }) : super(key: key);

  @override
  State<ExcursionScreen> createState() => _ExcursionScreenState();
}

class _ExcursionScreenState extends State<ExcursionScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Загрузка экскурсии...';
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _startExcursion();
  }

  Future<void> _startExcursion() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Подключение к гиду (сервер просыпается, подождите)...';
    });

    try {
      // Убран жёсткий 10-секундный .timeout(), используется таймаут из ApiService (90 сек)
      final response = await ApiService.askGuide(
        lat: widget.lat,
        lng: widget.lng,
        guideId: widget.guideId,
        userQuestion: 'Начни экскурсию по текущим координатам',
      );

      setState(() {
        _isLoading = false;
        _statusMessage = response['text_response'] ?? response['answer'] ?? 'Экскурсия начата';
        _audioUrl = ApiService.formatAudioUrl(response['audio_url']);
      });

      if (_audioUrl != null) {
        // Здесь вызов вашего AudioPlayer
        // await _audioPlayer.play(UrlSource(_audioUrl!));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка при попытке начать экскурсию: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLatLng = LatLng(widget.lat, widget.lng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Интерактивная экскурсия'),
      ),
      body: Column(
        children: [
          // Виджет Карты
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: currentLatLng,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Обязательно укажите package name, иначе OSM блокирует тайлы (серый экран)
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
          
          // Панель статуса / ответа гида
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
                      'Гид: ${widget.guideId}',
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
