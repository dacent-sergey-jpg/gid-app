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

  double _currentLat = 59.2205;
  double _currentLng = 39.8915;
  late String _currentGuideId;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _currentGuideId = widget.guideId ?? 'VOLOGDA_GUIDE';

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

  Future<void> _initLocationAndStart() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
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
          _statusMessage = 'Используются координаты по умолчанию (Вологда).';
        });
      }
    } finally {
      await _startExcursion();
    }
  }

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
        userQuestion: 'Расскажи про текущее место.',
      );

      final textResponse = response['text_response'] ?? response['answer'] ?? 'Информация загружена.';
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
          _statusMessage = 'Ошибка при запросе к гиду: $e';
        });
      }
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print('Ошибка воспроизведения: $e');
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
          
          // Безопасная нижняя панель без наложения на системные кнопки
          SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.record_voice_over)),
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
                          iconSize: 40,
                          color: Theme.of(context).primaryColor,
                          onPressed: _toggleAudio,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                  ],
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
