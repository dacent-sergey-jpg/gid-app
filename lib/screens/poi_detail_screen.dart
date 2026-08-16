import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../models/poi_model.dart';

class PoiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> poi;

  const PoiDetailScreen({
    super.key,
    required this.poi,
  });

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  final TextEditingController _questionController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = false;
  bool _isPlayingAudio = false;
  bool _isFavorite = false;
  String _guideAnswer = "";
  String? _audioUrl;
  String _selectedGuide = "alexander";

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = state == PlayerState.playing;
        });
      }
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final poiId = widget.poi['id']?.toString();
    if (poiId != null) {
      final isFav = await PreferencesService.isFavorite(poiId);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final poiModel = PoiModel.fromJson(widget.poi);
    await PreferencesService.toggleFavorite(poiModel);
    if (mounted) {
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioUrl == null || _audioUrl!.isEmpty) return;

    if (_isPlayingAudio) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(_audioUrl!));
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _askGuideAction() async {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _guideAnswer = "Гид готовится к ответу...";
      _audioUrl = null;
    });

    try {
      final poiId = widget.poi['id']?.toString();
      final response = await ApiService.askGuide(
        question: questionText,
        guideId: _selectedGuide,
        poiId: poiId,
      );

      final text = response['text'] ?? response['answer'] ?? "Ответ получен.";
      final rawAudioUrl = response['audio_url'] ?? response['audio'] ?? response['voice_url'];
      final formattedAudioUrl = ApiService.formatAudioUrl(rawAudioUrl?.toString());

      if (!mounted) return;

      setState(() {
        _guideAnswer = text;
        _audioUrl = formattedAudioUrl;
      });

      if (formattedAudioUrl != null && formattedAudioUrl.isNotEmpty) {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(formattedAudioUrl));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guideAnswer = "Ошибка при запросе: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.poi['title'] ?? widget.poi['name'] ?? 'Достопримечательность';
    final description = widget.poi['description'] ?? 'Описание отсутствует.';
    final imageUrl = widget.poi['image_url'] ?? widget.poi['imageUrl'] ?? widget.poi['photo'];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? Colors.amber : null,
              size: 28,
            ),
            tooltip: _isFavorite ? 'Убрать из избранного' : 'В избранное',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.toString().isNotEmpty)
              Image.network(
                imageUrl.toString(),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const Divider(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Задать вопрос гиду:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _selectedGuide,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'alexander', child: Text('👨 Александр')),
                          DropdownMenuItem(value: 'anna', child: Text('👩 Анна')),
                          DropdownMenuItem(value: 'mikhail', child: Text('🧔 Михаил')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGuide = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Спросите об истории, архитектуре...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _askGuideAction,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isLoading ? "Думает..." : "Задать вопрос"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  if (_guideAnswer.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFF0F3FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFF6C5CE7).withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ответ гида:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6C5CE7),
                                    fontSize: 16,
                                  ),
                                ),
                                if (_audioUrl != null && _audioUrl!.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      _isPlayingAudio
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: const Color(0xFF6C5CE7),
                                      size: 36,
                                    ),
                                    onPressed: _toggleAudioPlayback,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _guideAnswer,
                              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
