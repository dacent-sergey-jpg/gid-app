import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class GuideSelectionScreen extends StatefulWidget {
  final VoidCallback onGuideSelected;

  const GuideSelectionScreen({
    super.key,
    required this.onGuideSelected,
  });

  @override
  State<GuideSelectionScreen> createState() => _GuideSelectionScreenState();
}

class _GuideSelectionScreenState extends State<GuideSelectionScreen> {
  late String _selectedVoice;

  final List<Map<String, String>> _guides = const [
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
  void initState() {
    super.initState();
    // Инициализация из уже сохраненных настроек
    _selectedVoice = PreferencesService.getSelectedVoice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Выберите вашего гида',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: isSelected ? 2 : 0,
                        shadowColor: Colors.deepPurple.withOpacity(0.2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _selectedVoice = guide['id']!;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.black12,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey[200],
                                  child: Text(
                                    guide['name']![0],
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            guide['name']!,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.deepPurple,
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                      Text(
                                        guide['role']!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        guide['desc']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await PreferencesService.setSelectedVoice(_selectedVoice);
                    await PreferencesService.setOnboardingCompleted(true);
                    if (!mounted) return;
                    widget.onGuideSelected();
                  },
                  child: const Text(
                    'Начать прогулку',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
