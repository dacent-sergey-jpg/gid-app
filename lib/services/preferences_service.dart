import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static SharedPreferences? _prefs;

  // Ключи хранения
  static const String _keySelectedVoice = 'selected_voice';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keySpeechSpeed = 'speech_speed';
  static const String _keyAutoPlayAudio = 'auto_play_audio';

  // Значения по умолчанию
  static const String defaultVoice = 'anna';
  static const double defaultSpeechSpeed = 1.0;
  static const bool defaultAutoPlayAudio = true;

  /// Инициализация сервиса при старте приложения
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
        'PreferencesService не инициализирован. Вызовите PreferencesService.init() в main()',
      );
    }
    return _prefs!;
  }

  // --- Голос гида ---
  static Future<bool> setSelectedVoice(String voiceId) async {
    return await _instance.setString(_keySelectedVoice, voiceId);
  }

  static String getSelectedVoice() {
    return _instance.getString(_keySelectedVoice) ?? defaultVoice;
  }

  // --- Онбординг ---
  static Future<bool> setOnboardingCompleted(bool completed) async {
    return await _instance.setBool(_keyOnboardingCompleted, completed);
  }

  static bool isOnboardingCompleted() {
    return _instance.getBool(_keyOnboardingCompleted) ?? false;
  }

  // --- Скорость воспроизведения ---
  static Future<bool> setSpeechSpeed(double speed) async {
    return await _instance.setDouble(_keySpeechSpeed, speed);
  }

  static double getSpeechSpeed() {
    return _instance.getDouble(_keySpeechSpeed) ?? defaultSpeechSpeed;
  }

  // --- Автовоспроизведение аудио ---
  static Future<bool> setAutoPlayAudio(bool enabled) async {
    return await _instance.setBool(_keyAutoPlayAudio, enabled);
  }

  static bool getAutoPlayAudio() {
    return _instance.getBool(_keyAutoPlayAudio) ?? defaultAutoPlayAudio;
  }

  // --- Сброс настроек ---
  static Future<bool> clearAll() async {
    return await _instance.clear();
  }
}
