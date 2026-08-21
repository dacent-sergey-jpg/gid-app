import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
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
  final MapController _mapController = MapController();

  bool _isLoading = false;
  bool _isPlaying = false;
  String _statusMessage = 'Определение местоположения...';
  String? _audioUrl;

  // Координаты по умолчанию (Вологда), если GPS не сработает
  double _currentLat = 59.2205;
  double _currentLng = 39.8915;
  late String _currentGuideId;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Отслеживание состояния аудио
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _currentGuideId = widget.guideId ?? 'VOLOGDA_GUIDE';

    // Если координаты переданы извне — используем их, иначе запрашиваем GPS
    if (widget.lat != null && widget.lng != null) {
      _currentLat = widget.lat!;
      _currentLng = widget.lng!;
      _startExcursion();
    } else {
      _initLocationAndStart();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Получение геопозиции и запуск экскурсии
  Future<void> _initLocationAndStart() async {
    try {
      Position position = await _determinePosition();
      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
        _mapController.move(LatLng(_currentLat, _currentLng), 15.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Геолокация недоступна ($e). Используются координаты по умолчанию.';
        });
      }
    } finally {
      await _startExcursion();
    }
  }

  /// Проверка разрешений и получение GPS
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Геолокация отключена на устройстве');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Разрешение на доступ к геопозиции отклонено');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Разрешение на геопозицию запрещено навсегда');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Запрос данных экскурсии с бэкенда
  Future<void> _startExcursion() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Подключение к гиду...';
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

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = textResponse;
          _audioUrl = formattedUrl;
        });
      }

      if (_audioUrl != null && _audioUrl!.isNotEmpty) {
        await _playAudio(_audioUrl!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Ошибка при попытке начать экскурсию: $e';
        });
      }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _initLocationAndStart,
            tooltip: 'Обновить геопозицию',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
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
