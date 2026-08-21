import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:audioplayers/audioplayers.dart';
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
  late final AudioPlayer _audioPlayer;
  bool _isLoading = false;
  bool _isPlaying = false;
  String _statusMessage = 'Загрузка экскурсии...';
  String? _audioUrl;

  late double _currentLat;
  late double _currentLng;
  late String _currentGuideId;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Отслеживаем состояние воспроизведения
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _currentLat = widget.lat ?? 59.2205;
    _currentLng = widget.lng ?? 39.8915;
    _currentGuideId = widget.guideId ?? 'VOLOGDA_GUIDE';
    _startExcursion();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startExcursion() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Подключение к гиду (генерируем ответ и озвучку)...';
    });

    try {
      final response = await ApiService.askGuide(
        lat: _currentLat,
        lng: _currentLng,
        guideId: _currentGuideId,
        userQuestion: 'Привет! Расскажи коротко про это место и что ты умеешь.',
      );

      final textResponse = response['text_response'] ?? response['answer'] ?? 'Экскурсия начата';
      final formattedUrl = ApiService.formatAudioUrl(response['audio_url']);

      setState(() {
        _isLoading = false;
        _statusMessage = textResponse;
        _audioUrl = formattedUrl;
      });

      // Автоматический запуск озвучки при получении ссылки
      if (_audioUrl != null && _audioUrl!.isNotEmpty) {
        await _playAudio(_audioUrl!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка при попытке начать экскурсию: $e';
      });
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print('Ошибка воспроизведения аудио: $e');
    }
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else if (_audioUrl != null && _audioUrl!.isNotEmpty) {
      await _audioPlayer.play(UrlSource(_audioUrl!));
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
          // Интерактивная карта OpenStreetMap
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
          
          // Панель статуса и управления аудиоплеером
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
                    Expanded(
                      child: Text(
                        'Гид: $_currentGuideId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_audioUrl != null)
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                        iconSize: 44,
                        color: Theme.of(context).primaryColor,
                        onPressed: _toggleAudio,
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
