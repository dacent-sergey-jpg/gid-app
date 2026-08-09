import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/api_service.dart';

List<PoiModel> favoritePoiList = [];

void main() {
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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => isGpsLoading = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => isGpsLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
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
  }

  void _toggleExcursion() {
    setState(() {
      isExcursionActive = !isExcursionActive;
    });
  }

  void _showProfileDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFFF5722),
                    child: Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Турист', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Тариф: Премиум-Аудиогид', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.language, color: Color(0xFFFF5722)),
                title: const Text('Язык экскурсии'),
                trailing: const Text('Русский', style: TextStyle(color: Colors.grey)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Color(0xFFFF5722)),
                title: const Text('Обновить GPS'),
                onTap: () {
                  Navigator.pop(context);
                  _determinePosition();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GID v2.0',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: _showProfileDialog,
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
                    isGpsLoading ? 'Определение GPS...' : 'GPS определен',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                isExcursionActive ? 'ЭКСКУРСИЯ АКТИВНА' : 'ЭКСКУРСИЯ ПРИОСТАНОВЛЕНА',
                style: TextStyle(
                  color: isExcursionActive ? const Color(0xFF66BB6A) : Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'GPS: ${currentLat.toStringAsFixed(5)}, ${currentLon.toStringAsFixed(5)}',
                style: const TextStyle(color: Color(0xFFFF9800), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: _toggleExcursion,
                child: Container(
                  width: 170,
                  height: 170,
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
              const SizedBox(height: 35),

              _buildMenuButton(
                icon: Icons.map_outlined,
                title: 'Карта объектов',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapScreen(lat: currentLat, lon: currentLon)),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildMenuButton(
                icon: Icons.camera_alt_outlined,
                title: 'Что это? (AI Сканер)',
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
              const SizedBox(height: 16),
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

  const MapScreen({super.key, required this.lat, required this.lon});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<PoiModel>> _poiFuture;
  final AudioPlayer _audioPlayer = AudioPlayer();
  PoiModel? _playingPoi;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _poiFuture = ApiService.fetchNearbyPoi(lat: widget.lat, lon: widget.lon);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(PoiModel item) async {
    if (_playingPoi?.id == item.id && _isPlaying) {
      await _audioPlayer.pause();
    } else {
      _playingPoi = item;
      // Тестовый поток реального аудио если audioUrl пуст
      final url = item.audioUrl.startsWith('http')
          ? item.audioUrl
          : 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    }
  }

  void _toggleFavorite(PoiModel item) {
    setState(() {
      if (favoritePoiList.any((e) => e.id == item.id)) {
        favoritePoiList.removeWhere((e) => e.id == item.id);
      } else {
        favoritePoiList.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карта и Достопримечательности')),
      body: FutureBuilder<List<PoiModel>>(
        future: _poiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Рядом с вами объектов не найдено'));
          }

          final poiList = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: poiList.length,
                  itemBuilder: (context, index) {
                    final item = poiList[index];
                    final isFav = favoritePoiList.any((e) => e.id == item.id);
                    final isCurrentPlaying = _playingPoi?.id == item.id && _isPlaying;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xFF1E1E1E),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('${item.distanceMeters.toStringAsFixed(0)} м от вас', style: const TextStyle(color: Color(0xFFFF9800))),
                        trailing: IconButton(
                          icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.grey),
                          onPressed: () => _toggleFavorite(item),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description, style: const TextStyle(color: Colors.grey, height: 1.4)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5722),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 45),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _playAudio(item),
                                  icon: Icon(isCurrentPlaying ? Icons.pause_circle : Icons.play_circle),
                                  label: Text(isCurrentPlaying ? 'Пауза' : 'Слушать аудиогид'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (_playingPoi != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audiotrack, color: Color(0xFFFF5722)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_playingPoi!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_isPlaying ? 'Воспроизведение...' : 'На паузе', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        onPressed: () => _playAudio(_playingPoi!),
                      ),
                    ],
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
  bool _isScanning = false;
  PoiModel? _recognizedPoi;

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _recognizedPoi = null;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isScanning = false;
        _recognizedPoi = PoiModel(
          id: 1,
          title: 'Софийский собор',
          description: 'Древнейшее сохранившееся каменное здание Вологды, возведенное по повелению Ивана Грозного в 1568—1570 годах.',
          lat: 59.2244,
          lon: 39.8837,
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          distanceMeters: 15.0,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Визуальный сканер (AI)')),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: _isScanning ? const Color(0xFFFF5722) : Colors.white54, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: _isScanning
                      ? const CircularProgressIndicator(color: Color(0xFFFF5722))
                      : const Icon(Icons.camera_enhance_outlined, size: 64, color: Colors.white38),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (_recognizedPoi != null) ...[
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
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF66BB6A)),
                            const SizedBox(width: 8),
                            Text(_recognizedPoi!.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_recognizedPoi!.description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                    onPressed: _isScanning ? null : _startScanning,
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: Text(
                      _isScanning ? 'Сканирование...' : 'Распознать объект',
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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранные места')),
      body: favoritePoiList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star_outline, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Список избранного пуст', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Добавляйте объекты из карты со звездочкой', style: TextStyle(color: Colors.white38)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoritePoiList.length,
              itemBuilder: (context, index) {
                final item = favoritePoiList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          favoritePoiList.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
