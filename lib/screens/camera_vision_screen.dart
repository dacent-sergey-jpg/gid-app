import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import '../main.dart'; // Извлекаем глобальный список cameras

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  XFile? _capturedImage;
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      try {
        cameras = await availableCameras();
      } catch (e) {
        print('Камеры недоступны: $e');
      }
    }

    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.high);
      await _controller!.initialize();
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhotoAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isAnalyzing) return;

    try {
      setState(() {
        _isAnalyzing = true;
        _resultText = 'Анализируем изображение...';
      });

      // 1. Фиксируем снимок с камеры
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
      });

      // 2. Отправляем файл на бэкенд AI Vision
      final result = await ApiService.analyzeImage(File(image.path));

      setState(() {
        _isAnalyzing = false;
        _resultText = result['description'] ?? result['text'] ?? 'Объект распознан';
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _resultText = 'Ошибка распознавания: $e';
      });
    }
  }

  void _resetPhoto() {
    setState(() {
      _capturedImage = null;
      _resultText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Что это? (AI Vision)'),
        actions: [
          if (_capturedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetPhoto,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Превью камеры или зафиксированный снимок
          Positioned.fill(
            child: _capturedImage != null
                ? Image.file(File(_capturedImage!.path), fit: BoxFit.cover)
                : (_controller != null && _controller!.value.isInitialized
                    ? CameraPreview(_controller!)
                    : const Center(child: Text('Камера недоступна'))),
          ),

          // Результат распознавания внизу экрана с поддержкой SafeArea
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_resultText != null) ...[
                        Text(
                          _resultText!,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _takePhotoAndAnalyze,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(_isAnalyzing ? 'Распознавание...' : 'Распознать объект'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
