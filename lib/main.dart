import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'screens/main_home_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация камер и запрос разрешений при старте
  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Ошибка инициализации камеры: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
  }

  Future<void> _requestAllPermissions() async {
    // 1. Запрос геопозиции
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ГИД Вологда',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}
