import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';

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
  String _activeGuide = PreferencesService.defaultVoice;
  Position? _currentPosition;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _isMapView = widget.startInMapView;
    _activeGuide = PreferencesService.getSelectedVoice();
    _initAudioListeners();
    _startExcursion();
  }

  void _initAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() => _position = newPosition);
      }
    });
  }

  Future<void> _startExcursion() async {
    setState(() {
      _isLoading = true;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    await _audioPlayer.stop();

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
          timeLimit: const Duration(seconds: 10),
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

      final text = result['answer'] ?? result['text'] ?? 'История недоступна.';
      setState(() {
        _currentStory = text;
      });

      final formattedAudio = result['audio_url']?.toString();
      if (formattedAudio != null && formattedAudio.isNotEmpty) {
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
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
      padding: const EdgeInsets.all(16.0),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Гид: ${_activeGuide.toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
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
          const SizedBox(height: 12),
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
          bottom: 16,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_duration > Duration.zero) ...[
              Slider(
                min: 0.0,
                max: _duration.inSeconds.toDouble(),
                value: _position.inSeconds.toDouble().clamp(
                      0.0,
                      _duration.inSeconds.toDouble(),
                    ),
                onChanged: (value) async {
                  final position = Duration(seconds: value.toInt());
                  await _audioPlayer.seek(position);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                  iconSize: 48,
                  color: Theme.of(context).primaryColor,
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
          ],
        ),
      ),
    );
  }
}
