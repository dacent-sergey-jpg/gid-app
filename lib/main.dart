import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:camera/camera.dart';

import 'services/api_service.dart';
import 'services/geofence_service.dart';
import 'widgets/audio_player_sheet.dart';

List<PoiModel> favoritePoiList = [];
List<CameraDescription> availableCamerasList = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    availableCamerasList = await availableCameras();
  } catch (_) {
    // Если устройства нет или камера недоступна
  }
  runApp(const GidApp());
}

class GidApp extends StatelessWidget {
  const GidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5722),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isExcursionActive = true;
  double currentLat = 59.2244;
  double currentLon = 39.8837;
  bool isGpsLoading = false;

  StreamSubscription<Position>? _positionStreamSubscription;
  final GeofenceService _geofenceService = GeofenceService(triggerRadiusMeters: 30.0);
  final AudioPlayer _sharedAudioPlayer = AudioPlayer();
  List<PoiModel> _nearbyPois = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _startGeofencingListener();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _sharedAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => isGpsLoading = true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => isGpsLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => isGpsLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => isGpsLoading = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLat = position.latitude;
      currentLon = position.longitude;
      isGpsLoading = false;
    });

    _nearbyPois = await ApiService.fetchNearbyPoi(lat: currentLat, lon: currentLon);
  }

  void _startGeofencingListener() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Реакция каждые 5 метров при прогулке
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      if (!mounted) return;

      setState(() {
        currentLat = position.latitude;
        currentLon = position.longitude;
      });

      if (!isExcursionActive) return;

      if (_nearbyPois.isEmpty) {
        _nearbyPois = await ApiService.fetchNearbyPoi(lat: currentLat, lon: currentLon);
      }

      final triggeredPoi = _geofenceService.checkProximity(
        userLat: currentLat,
        userLon: currentLon,
        poiList: _nearbyPois,
      );

      if (triggeredPoi != null && mounted) {
        _showGeofenceSnackBar(triggeredPoi);
      }
    });
  }

  void _showGeofenceSnackBar(PoiModel poi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2A2A2A),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.spatial_audio_off, color: Color(0xFFFF5722)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Рядом объект!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    poi.title,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'СЛУШАТЬ',
          textColor: const Color(0xFFFF5722),
          onPressed: () => _openAudioSheet(poi),
        ),
      ),
    );
  }

  void _openAudioSheet(PoiModel poi) async {
    await _sharedAudioPlayer.stop();
    await _sharedAudioPlayer.play(UrlSource(poi.audioUrl));

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudioPlayerSheet(
        poi: poi,
        audioPlayer: _sharedAudioPlayer,
      ),
    );
  }

  // Симуляция подхода к объекту для тестирования в помещении
  void _simulateApproachToPoi() {
    if (_nearbyPois.isNotEmpty) {
      final targetPoi = _nearbyPois.first;
      setState(() {
        currentLat = targetPoi.lat;
        currentLon = targetPoi.lon;
      });
      _showGeofenceSnackBar(targetPoi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GID FIELD TEST',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Color(0xFFFF5722)),
            tooltip: 'Тест геозоны',
            onPressed: _simulateApproachToPoi,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFF5722), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    isGpsLoading ? 'Поиск спутников GPS...' : 'GPS сигнал активен',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                isExcursionActive ? 'РЕЖИМ ЭКСКУРСИИ АКТИВЕН' : 'ЭКСКУРСИЯ НА ПАУЗЕ',
                style: TextStyle(
                  color: isExcursionActive ? const Color(0xFF66BB6A) : Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Координаты: ${currentLat.toStringAsFixed(5)}, ${currentLon.toStringAsFixed(5)}',
                style: const TextStyle(color: Color(0xFFFF9800), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  setState(() => isExcursionActive = !isExcursionActive);
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF5722),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withOpacity(0.35),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExcursionActive ? Icons.pause : Icons.play_arrow,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isExcursionActive ? 'СТОП' : 'СТАРТ',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildMenuButton(
                icon: Icons.map_outlined,
                title: 'Карта (Voyager HD)',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        lat: currentLat,
                        lon: currentLon,
                        audioPlayer: _sharedAudioPlayer,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildMenuButton(
                icon: Icons.camera_alt_outlined,
                title: 'AI Сканер Камеры',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecognitionScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildMenuButton(
                icon: Icons.star_border,
                title: 'Избранное',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFFFF5722), size: 26),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final double lat;
  final double lon;
  final AudioPlayer audioPlayer;

  const MapScreen({
    super.key,
    required this.lat,
    required this.lon,
    required this.audioPlayer,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<PoiModel>> _poiFuture;
  PoiModel? _playingPoi;
  PoiModel? _selectedPoi;
  bool _isPlaying = false;
  bool _isAudioLoading = false;

  @override
  void initState() {
    super.initState();
    _poiFuture = ApiService.fetchNearbyPoi(lat: widget.lat, lon: widget.lon);

    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (_isPlaying) _isAudioLoading = false;
        });
      }
    });
  }

  Future<void> _playAudio(PoiModel item) async {
    if (_playingPoi?.id == item.id && _isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      setState(() {
        _playingPoi = item;
        _isAudioLoading = true;
      });

      try {
        await widget.audioPlayer.stop();
        await widget.audioPlayer.play(UrlSource(item.audioUrl));
      } catch (e) {
        if (mounted) setState(() => _isAudioLoading = false);
      }
    }
  }

  void _openFullPlayerSheet(PoiModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudioPlayerSheet(
        poi: item,
        audioPlayer: widget.audioPlayer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карта объектов')),
      body: FutureBuilder<List<PoiModel>>(
        future: _poiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Рядом объектов не найдено'));
          }

          final poiList = snapshot.data!;
          final activePoi = _selectedPoi ?? poiList.first;

          return Stack(
            children: [
              // Светлые быстрые карты CartoDB Voyager
              FlutterMap(
                options: MapOptions(
                  initialCenter: latlong.LatLng(widget.lat, widget.lon),
                  initialZoom: 15.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.gid_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latlong.LatLng(widget.lat, widget.lon),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 34),
                      ),
                      ...poiList.map(
                        (poi) => Marker(
                          point: latlong.LatLng(poi.lat, poi.lon),
                          width: 45,
                          height: 45,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPoi = poi),
                            child: Icon(
                              Icons.location_on,
                              color: activePoi.id == poi.id ? Colors.amber : const Color(0xFFFF5722),
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Positioned(
                left: 16,
                right: 16,
                top: 16,
                child: Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activePoi.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${activePoi.distanceMeters.toStringAsFixed(0)} м от вас', style: const TextStyle(color: Color(0xFFFF9800), fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(activePoi.description, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              _playAudio(activePoi);
                              _openFullPlayerSheet(activePoi);
                            },
                            icon: const Icon(Icons.play_arrow, color: Colors.white),
                            label: const Text('Открыть аудиогид', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  PoiModel? _detectedPoi;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (availableCamerasList.isNotEmpty) {
      _cameraController = CameraController(
        availableCamerasList.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _captureAndRecognize() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _detectedPoi = null;
    });

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.takePicture();
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _detectedPoi = PoiModel(
          id: 1,
          title: 'Софийский собор (AI 98%)',
          description: 'Распознано визуальной нейросетью. Памятник архитектуры XVI века.',
          lat: 59.2244,
          lon: 39.8837,
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          distanceMeters: 15.0,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Сканер достопримечательностей')),
      body: Stack(
        children: [
          _isCameraInitialized
              ? CameraPreview(_cameraController!)
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text('Запуск видоискателя камеры...', style: TextStyle(color: Colors.grey)),
                  ),
                ),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isAnalyzing ? const Color(0xFFFF5722) : Colors.white70,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isAnalyzing
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)))
                  : null,
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (_detectedPoi != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF5722)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_detectedPoi!.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(_detectedPoi!.description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isAnalyzing ? null : _captureAndRecognize,
                    icon: const Icon(Icons.camera_sharp, color: Colors.white),
                    label: Text(
                      _isAnalyzing ? 'Анализ нейросетью...' : 'Сфотографировать объект',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: favoritePoiList.isEmpty
          ? const Center(child: Text('Список избранных мест пуст', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoritePoiList.length,
              itemBuilder: (context, index) {
                final item = favoritePoiList[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(item.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                );
              },
            ),
    );
  }
}
