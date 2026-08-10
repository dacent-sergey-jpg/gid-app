import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Адрес вашего бэкенда на Render
  static const String baseUrl = 'https://gid-backend-oi81.onrender.com/api/v1';

  /// Получение объектов поблизости из PostGIS по текущим координатам
  static Future<List<dynamic>> fetchNearbyPois({
    required double lat,
    required double lon,
    double radiusMeters = 5000.0,
  }) async {
    final url = Uri.parse('$baseUrl/nearby?lat=$lat&lon=$lon&radius_meters=$radiusMeters');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке мест: $e');
      rethrow;
    }
  }

  /// Запрос к AI-гиду (RAG + Gemini + Neural TTS)
  static Future<Map<String, dynamic>> askGuide({
    required int poiId,
    required String question,
    required String voiceId,
  }) async {
    final url = Uri.parse('$baseUrl/ask-guide');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'poi_id': poiId,
          'user_question': question,
          'voice_id': voiceId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Ошибка ответа гида: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при обращении к гиду: $e');
      rethrow;
    }
  }
}
