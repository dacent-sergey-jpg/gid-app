import 'package:flutter/material.dart';
import 'screens/guide_selection_screen.dart';
import 'screens/main_home_screen.dart';
import 'services/preferences_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GidApp());
}

class GidApp extends StatelessWidget {
  const GidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          primary: const Color(0xFF6C5CE7),
        ),
      ),
      home: const MainWrapper(),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isOnboardingDone) {
      return GuideSelectionScreen(
        onGuideSelected: () {
          setState(() => _isOnboardingDone = true);
        },
      );
    }

    return const MainHomeScreen();
  }
}
