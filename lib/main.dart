import 'package:flutter/material.dart';
import 'screens/poi_detail_screen.dart';
import 'screens/guide_selection_screen.dart';
import 'services/api_service.dart';
import 'services/preferences_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ГИД Приложение',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MainWrapper(),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  bool _isLoading = true;
  bool _isOnboardingDone = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final completed = await PreferencesService.isOnboardingCompleted();
    setState(() {
      _isOnboardingDone = completed;
      _isLoading = false;
    });
  }

  void _onGuideSelected() {
    setState(() {
      _isOnboardingDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isOnboardingDone) {
      return GuideSelectionScreen(onGuideSelected: _onGuideSelected);
    }

    return const HomeScreen();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _pois = [];
  bool _loadingPois = true;
  String _selectedVoice = 'anna';

  // Координаты по умолчанию (Центр Вологды: Софийский собор)
  final double _defaultLat = 59.224167;
  final double _defaultLon = 39.883889;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final voice = await PreferencesService.getSelectedVoice();
    setState(() {
      _selectedVoice = voice;
    });

    await _fetchNearbyPlaces();
  }

  Future<void> _fetchNearbyPlaces() async {
    setState(() {
      _loadingPois = true;
    });

    try {
      final places = await ApiService.fetchNearbyPois(
        lat: _defaultLat,
        lon: _defaultLon,
        radiusMeters: 5000,
      );
      setState(() {
        _pois = places;
        _loadingPois = false;
      });
    } catch (e) {
      setState(() {
        _loadingPois = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки точек: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аудиогид по Вологде'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Сменить гида',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GuideSelectionScreen(
                    onGuideSelected: () {
                      Navigator.of(context).pop();
                      _loadInitialData();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loadingPois
          ? const Center(child: CircularProgressIndicator())
          : _pois.isEmpty
              ? const Center(child: Text('Рядом не найдено объектов'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pois.length,
                  itemBuilder: (context, index) {
                    final poi = _pois[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.place),
                        ),
                        title: Text(
                          poi['title'] ?? 'Без названия',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          poi['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PoiDetailScreen(poi: poi),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
