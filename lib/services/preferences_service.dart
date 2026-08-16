import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poi_model.dart';

class PreferencesService {
  static const String _favoritesKey = 'favorite_pois';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _selectedVoiceKey = 'selected_voice';

  /// Голос гида по умолчанию
  static const String defaultVoice = 'vologda_guide';

  static String _cachedVoice = defaultVoice;

  /// Инициализация сервиса при старте приложения
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedVoice = prefs.getString(_selectedVoiceKey) ?? defaultVoice;
  }

  // === Избранное (POI) ===

  /// Получить список всех избранных POI
  static Future<List<PoiModel>> getFavoritePois() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_favoritesKey) ?? [];
    return rawList
        .map((item) => PoiModel.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  /// Проверить, находится ли POI в избранном по id
  static Future<bool> isFavorite(String poiId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_favoritesKey) ?? [];
    return rawList.any((item) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      return (map['id'] ?? map['poi_id'] ?? '').toString() == poiId;
    });
  }

  /// Добавить/удалить POI из избранного
  static Future<bool> toggleFavorite(PoiModel poi) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_favoritesKey) ?? [];

    final existingIndex = rawList.indexWhere((item) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      return (map['id'] ?? map['poi_id'] ?? '').toString() == poi.id;
    });

    bool isNowFavorite;
    if (existingIndex >= 0) {
      rawList.removeAt(existingIndex);
      isNowFavorite = false;
    } else {
      rawList.add(jsonEncode(poi.toJson()));
      isNowFavorite = true;
    }

    await prefs.setStringList(_favoritesKey, rawList);
    return isNowFavorite;
  }

  // === Онбординг ===

  /// Проверить, пройден ли онбординг
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedVoice = prefs.getString(_selectedVoiceKey) ?? defaultVoice;
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Сохранить статус прохождения онбординга
  static Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, completed);
  }

  // === Выбор голоса гида ===

  /// Получить текущий выбранный голос (синхронно из кэша)
  static String getSelectedVoice() {
    return _cachedVoice;
  }

  /// Сохранить новый голос гида
  static Future<void> setSelectedVoice(String voice) async {
    _cachedVoice = voice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedVoiceKey, voice);
  }
}
