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

class _CameraVisionScreenState extends State<CameraVisionScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  bool _isFlashOn = false;
  bool _isPlayingAudio = false;
  String _resultText = "Наведите камеру на здание или памятник";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();

    // Отслеживание состояния воспроизведения озвучки
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Принудительно выбираем заднюю камеру
        final backCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras![0],
        );

        _controller = CameraController(
          backCamera,
          ResolutionPreset.high,
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
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint("Ошибка вспышки: $e");
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _takePictureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized || _isAnalyzing) return;

    await _audioPlayer.stop();

    setState(() {
      _isAnalyzing = true;
      _resultText = "Анализирую изображение AI Vision...";
    });

    try {
      final XFile imageFile = await _controller!.takePicture();
      final response = await ApiService.analyzeImage(File(imageFile.path));

      if (!mounted) return;

      final text = response['description'] ??
          response['answer'] ??
          response['text'] ??
          "Объект успешно распознан!";
      final rawAudioUrl = response['audio_url'];
      final formattedAudioUrl = ApiService.formatAudioUrl(rawAudioUrl?.toString());

      setState(() {
        _resultText = text;
      });

      if (formattedAudioUrl != null && formattedAudioUrl.isNotEmpty) {
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Что это? (AI Vision)'),
        actions: [
          if (_isCameraInitialized)
            IconButton(
              icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isCameraInitialized && _controller != null)
            Center(
              child: CameraPreview(_controller!),
            )
          else
            const Center(child: CircularProgressIndicator()),

          Positioned(
            bottom: 16.0 + bottomPadding,
            left: 16.0,
            right: 16.0,
            child: Card(
              color: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Text(
                          _resultText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : _takePictureAndRecognize,
                            icon: _isAnalyzing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt),
                            label: Text(
                              _isAnalyzing ? "Распознавание..." : "Распознать объект",
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_isPlayingAudio) ...[
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _toggleAudioPlayback,
                            icon: const Icon(Icons.pause),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ],
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
