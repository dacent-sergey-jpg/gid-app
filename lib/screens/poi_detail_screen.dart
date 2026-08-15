import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class PoiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> poi;

  const PoiDetailScreen({Key? key, required this.poi}) : super(key: key);

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  final TextEditingController _questionController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = false;
  String _guideAnswer = "";
  String _selectedGuide = "alexander";

  @override
  void dispose() {
    _questionController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _askGuideAction() async {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) return;

    setState(() {
      _isLoading = true;
      _guideAnswer = "Гид сгенерирует ответ...";
    });

    try {
      final poiId = widget.poi['id']?.toString();
      final response = await ApiService.askGuide(
        question: questionText,
        guideId: _selectedGuide,
        poiId: poiId,
      );

      setState(() {
        _guideAnswer = response['text'] ?? response['answer'] ?? "Ответ получен.";
      });

      if (response['audio_url'] != null && response['audio_url'].toString().isNotEmpty) {
        await _audioPlayer.play(UrlSource(response['audio_url']));
      }
    } catch (e) {
      setState(() {
        _guideAnswer = "Ошибка при запросе: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.poi['title'] ?? widget.poi['name'] ?? 'Достопримечательность';
    final description = widget.poi['description'] ?? 'Описание отсутствует.';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
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
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Задать вопрос гиду:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                DropdownButton<String>(
                  value: _selectedGuide,
                  items: const [
                    DropdownMenuItem(value: 'alexander', child: Text('Александр')),
                    DropdownMenuItem(value: 'anna', child: Text('Анна')),
                    DropdownMenuItem(value: 'mikhail', child: Text('Михаил')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGuide = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                hintText: 'Спросите об истории, архитектуре...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _askGuideAction,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? "Думает..." : "Задать вопрос"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            if (_guideAnswer.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _guideAnswer,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
