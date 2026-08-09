import 'package:flutter/material.dart';
import 'services/api_service.dart';

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
  double currentLat = 59.18604;
  double currentLon = 39.92265;

  void _toggleExcursion() {
    setState(() {
      isExcursionActive = !isExcursionActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GID v2.0',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Профиль пользователя')),
              );
            },
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
                children: const [
                  Icon(Icons.location_on, color: Color(0xFFFF5722), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Вологда',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                isExcursionActive ? 'ЭКСКУРСИЯ АКТИВНА' : 'ЭКСКУРСИЯ ПРИОСТАНОВЛЕНА',
                style: TextStyle(
                  color: isExcursionActive ? const Color(0xFF66BB6A) : Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'GPS: ${currentLat.toStringAsFixed(5)}, ${currentLon.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: _toggleExcursion,
                child: Container(
                  width: 180,
                  height: 180,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),

              _buildMenuButton(
                icon: Icons.map_outlined,
                title: 'Карта',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(lat: currentLat, lon: currentLon),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildMenuButton(
                icon: Icons.camera_alt_outlined,
                title: 'Что это?',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFFFF5722), size: 26),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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

  @override
  void initState() {
    super.initState();
    _poiFuture = ApiService.fetchNearbyPoi(lat: widget.lat, lon: widget.lon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карта объектов')),
      body: FutureBuilder<List<PoiModel>>(
        future: _poiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Ошибка: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Объекты не найдены'));
          }

          final poiList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: poiList.length,
            itemBuilder: (context, index) {
              final item = poiList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text('${item.distanceMeters.toStringAsFixed(0)} м'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RecognitionScreen extends StatelessWidget {
  const RecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Что это?')),
      body: const Center(child: Text('Наведите камеру на объект', style: TextStyle(fontSize: 18))),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: const Center(child: Text('Список избранного пуст', style: TextStyle(fontSize: 18))),
    );
  }
}
