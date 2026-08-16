import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class ExcursionScreen extends StatefulWidget {
  final Map<String, dynamic>? poi;
  final bool startInMapView;

  const ExcursionScreen({
    super.key,
    this.poi,
    this.startInMapView = false,
  });

  @override
  State<ExcursionScreen> createState() => _ExcursionScreenState();
}

class _ExcursionScreenState extends State<ExcursionScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isMapView = false;
  bool _isLoading = false;
  bool _isPlaying = false;

  String _currentStory = 'Определение геопозиции и загрузка экскурсии...';
  final String _activeGuide = 'alexander';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _isMapView = widget.startInMapView;
    _initAudioListeners();
    _startExcursion();
  }

  void _initAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  Future<void> _startExcursion() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position;
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } else {
        position = Position(
          latitude: 59.2205,
          longitude: 39.8915,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      if (!mounted) return;
      setState(() => _currentPosition = position);

      final result = await ApiService.askGuide(
        lat: position.latitude,
        lng: position.longitude,
        guideId: _activeGuide,
        poiId: widget.poi?['id']?.toString(),
        question: widget.poi != null
            ? 'Расскажи историю про ${widget.poi!['title'] ?? 'это место'}'
            : 'Начни аудиоэкскурсию по текущему маршруту.',
      );

      if (!mounted) return;
      setState(() {
        _currentStory = result['text'] ?? 'История недоступна.';
      });

      final rawAudio = result['audio_url'] ?? result['audio'];
      final formattedAudio = ApiService.formatAudioUrl(rawAudio?.toString());
      if (formattedAudio != null) {
        await _audioPlayer.play(UrlSource(formattedAudio));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentStory = 'Ошибка при попытке начать экскурсию: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poi?['title'] ?? 'Интерактивная экскурсия'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            tooltip: _isMapView ? 'Список' : 'Карта',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Гид подбирает интересные факты...'),
                ],
              ),
            )
          : _isMapView
              ? _buildMapView()
              : _buildStoryView(),
    );
  }

  Widget _buildStoryView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(
                              Icons.record_voice_over,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Рассказывает Гид',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Режим прогулки',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        _currentStory,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        Container(
          color: Colors.blueGrey.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: Colors.blueGrey,
                ),
                const SizedBox(height: 12),
                Text(
                  _currentPosition != null
                      ? 'Координаты: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                      : 'Интеграция с картой',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: _buildAudioControls(),
        ),
      ],
    );
  }

  Widget _buildAudioControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                _isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
              ),
              iconSize: 48,
              color: const Color(0xFF6C5CE7),
              onPressed: () async {
                if (_isPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.resume();
                }
              },
            ),
            Expanded(
              child: Text(
                _isPlaying ? 'Аудиогид вещает...' : 'Воспроизведение на паузе',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Запросить заново',
              onPressed: _startExcursion,
            ),
          ],
        ),
      ),
    );
  }
}
