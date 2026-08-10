import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraVisionScreen extends StatefulWidget {
  const CameraVisionScreen({Key? key}) : super(key: key);

  @override
  State<CameraVisionScreen> createState() => _CameraVisionScreenState();
}

class _CameraVisionScreenState extends State<CameraVisionScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras.first, ResolutionPreset.medium);
        await _controller!.initialize();
      }
    } catch (e) {
      print('Ошибка камеры: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _analyzeImage() {
    setState(() => _isAnalyzing = true);

    // Имитация распознавания Vision AI
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Софийский собор',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Распознан памятник XVI века. Хотите прослушать историю?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.headphones, color: Colors.white),
                label: const Text('Рассказать', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Что это?', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _controller == null || !_controller!.value.isInitialized
              ? const Center(child: Text('Камера недоступна', style: TextStyle(color: Colors.white)))
              : Stack(
                  children: [
                    CameraPreview(_controller!),
                    Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton.extended(
                          backgroundColor: const Color(0xFF6C5CE7),
                          onPressed: _isAnalyzing ? null : _analyzeImage,
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                          label: Text(_isAnalyzing ? 'Распознаем...' : 'Распознать объект', style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    )
                  ],
                ),
    );
  }
}
