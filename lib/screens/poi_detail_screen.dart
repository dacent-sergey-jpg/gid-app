import 'package:flutter/material.dart';
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
  bool _isAsking = false;
  String? _answerText;
  String _selectedVoice = 'anna';

  @override
  void initState() {
    super.initState();
    _loadVoice();
  }

  Future<void> _loadVoice() async {
    final voice = await PreferencesService.getSelectedVoice();
    setState(() {
      _selectedVoice = voice;
    });
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

      setState(() {
        _answerText = response['answer'] ?? response['response'] ?? 'Гид ответил, но текст не найден.';
        _isAsking = false;
      });
      _questionController.clear();
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
            if (widget.poi['category'] != null)
              Chip(
                label: Text(widget.poi['category']),
                backgroundColor: Colors.deepPurple.shade50,
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Например: Кто автор построек?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
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
