import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ваш развернутый бэкенд на Render
  static const String baseUrl = 'https://gid-backend-oi81.onrender.com/api/v1';

  /// Запрос объектов поблизости из PostGIS
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
        throw Exception('Ошибка бэкенда: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при запросе точек: $e');
      rethrow;
    }
  }

  /// Задать вопрос гиду (RAG + LLM + TTS)
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
      print('Ошибка при вопросе гиду: $e');
      rethrow;
    }
  }
}
