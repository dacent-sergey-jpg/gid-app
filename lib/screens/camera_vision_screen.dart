import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class CameraVisionScreen extends StatefulWidget {
  const CameraVisionScreen({super.key});

  @override
  State<CameraVisionScreen> createState() => _CameraVisionScreenState();
}

class _CameraVisionScreenState extends State<CameraVisionScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  String _resultText = "Наведите камеру на здание или памятник";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Ошибка инициализации камеры: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _resultText = "Анализирую изображение AI Vision...";
    });

    try {
      final XFile imageFile = await _controller!.takePicture();
      final response = await ApiService.analyzeImage(File(imageFile.path));

      if (!mounted) return;

      final text = response['description'] ?? response['text'] ?? response['answer'] ?? "Объект успешно распознан!";
      final rawAudioUrl = response['audio_url'] ?? response['audio'] ?? response['voice_url'];
      final formattedAudioUrl = ApiService.formatAudioUrl(rawAudioUrl?.toString());

      setState(() {
        _resultText = text;
      });

      if (formattedAudioUrl != null && formattedAudioUrl.isNotEmpty) {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(formattedAudioUrl));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultText = "Ошибка распознавания: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Что это? (AI Vision)'),
      ),
      body: Stack(
        children: [
          if (_isCameraInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Center(child: CircularProgressIndicator()),

          Positioned(
            bottom: 24.0 + bottomPadding,
            left: 16.0,
            right: 16.0,
            child: Card(
              color: Colors.black.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _resultText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _takePictureAndRecognize,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(_isAnalyzing ? "Распознавание..." : "Распознать объект"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
