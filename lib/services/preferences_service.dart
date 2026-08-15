import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keySelectedVoice = 'selected_voice';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  static Future<void> setSelectedVoice(String voiceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedVoice, voiceId);
  }

  static Future<String> getSelectedVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedVoice) ?? 'anna';
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, completed);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }
}
