import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class GuideSelectionScreen extends StatefulWidget {
  final VoidCallback onGuideSelected;

  const GuideSelectionScreen({Key? key, required this.onGuideSelected}) : super(key: key);

  @override
  State<GuideSelectionScreen> createState() => _GuideSelectionScreenState();
}

class _GuideSelectionScreenState extends State<GuideSelectionScreen> {
  String _selectedVoice = 'anna';

  final List<Map<String, String>> _guides = [
    {
      'id': 'anna',
      'name': 'Анна',
      'role': 'Искусствовед и историк',
      'desc': 'Мягкий голос. Расскажет про архитектурные детали, фрески и легенды.',
    },
    {
      'id': 'alexander',
      'name': 'Александр',
      'role': 'Архитектор',
      'desc': 'Уверенный голос. Поделится фактами о строительстве города и секретных местах.',
    },
    {
      'id': 'mikhail',
      'name': 'Михаил',
      'role': 'Хранитель историй',
      'desc': 'Глубокий бархатный голос. Любит забавные байки и исторические анекдоты.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Выберите вашего гида', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _guides.length,
                  itemBuilder: (context, index) {
                    final guide = _guides[index];
                    final isSelected = _selectedVoice == guide['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedVoice = guide['id']!;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.deepPurple : Colors.black12,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[200],
                              child: Text(
                                guide['name']![0],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    guide['name']!,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    guide['role']!,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    guide['desc']!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    await PreferencesService.setSelectedVoice(_selectedVoice);
                    await PreferencesService.setOnboardingCompleted(true);
                    widget.onGuideSelected();
                  },
                  child: const Text(
                    'Начать прогулку',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
