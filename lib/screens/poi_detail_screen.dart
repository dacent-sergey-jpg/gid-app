import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';

class PoiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> poi;

  const PoiDetailScreen({Key? key, required this.poi}) : super(key: key);

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  final TextEditingController _questionController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlayingAudio = false;
  bool _isListeningVoice = false;
  bool _isAsking = false;
  String? _answerText;
  String _selectedVoice = 'anna';

  @override
  void initState() {
    super.initState();
    _loadVoice();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadVoice() async {
    final voice = await PreferencesService.getSelectedVoice();
    setState(() {
      _selectedVoice = voice;
    });
  }

  // Воспроизведение главного аудиогида по объекту
  Future<void> _togglePoiAudio() async {
    final audioUrl = widget.poi['audio_url'];
    if (audioUrl == null || audioUrl.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аудиозапись для этого объекта отсутствует')),
      );
      return;
    }

    if (_isPlayingAudio) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(audioUrl));
    }
  }

  // Симуляция голосового ввода (запись голоса)
  void _toggleVoiceInput() {
    setState(() {
      _isListeningVoice = !_isListeningVoice;
    });

    if (_isListeningVoice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Слушаю ваш вопрос... Говорите')),
      );
      // Имитация распознавания через 3 секунды
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isListeningVoice) {
          setState(() {
            _questionController.text = 'Расскажи подробнее про историю этого места';
            _isListeningVoice = false;
          });
          _askGuide();
        }
      });
    }
  }

  Future<void> _askGuide() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isAsking = true;
      _answerText = null;
    });

    try {
      final response = await ApiService.askGuide(
        poiId: widget.poi['id'],
        question: question,
        voiceId: _selectedVoice,
      );

      final answer = response['answer'] ?? response['response'] ?? 'Гид дал ответ.';
      final audioResponseUrl = response['audio_url'];

      setState(() {
        _answerText = answer;
        _isAsking = false;
      });
      _questionController.clear();

      // Если сервер прислал ссылку на сгенерированную озвучку ответа — воспроизводим
      if (audioResponseUrl != null && audioResponseUrl.toString().isNotEmpty) {
        await _audioPlayer.play(UrlSource(audioResponseUrl));
      }
    } catch (e) {
      setState(() {
        _isAsking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка ответа гида: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final facts = widget.poi['facts'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poi['title'] ?? 'Достопримечательность'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Плеер аудиогида
            Card(
              color: Colors.deepPurple.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: Icon(
                      _isPlayingAudio ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _togglePoiAudio,
                  ),
                ),
                title: const Text('Слушать аудиогид', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isPlayingAudio ? 'Воспроизведение...' : 'Нажмите для запуска'),
              ),
            ),
            const SizedBox(height: 16),

            if (widget.poi['category'] != null)
              Chip(
                label: Text(widget.poi['category']),
                backgroundColor: Colors.deepPurple.shade100,
              ),
            const SizedBox(height: 12),
            Text(
              widget.poi['description'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),

            if (facts.isNotEmpty) ...[
              const Text(
                'Интересные факты',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...facts.map((fact) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(fact.toString(), style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Задать вопрос гиду',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Поле ввода + Голосовой ввод + Отправка
            Row(
              children: [
                IconButton(
                  onPressed: _toggleVoiceInput,
                  icon: Icon(
                    _isListeningVoice ? Icons.mic_sharp : Icons.mic_none,
                    color: _isListeningVoice ? Colors.red : Colors.deepPurple,
                    size: 28,
                  ),
                  tooltip: 'Голосовой вопрос',
                ),
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: _isListeningVoice ? 'Говорите...' : 'Спросите голосом или текстом...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: _isAsking ? null : _askGuide,
                  icon: _isAsking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),

            if (_answerText != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.record_voice_over, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'Ответ гида:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_answerText!, style: const TextStyle(fontSize: 15, height: 1.3)),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
