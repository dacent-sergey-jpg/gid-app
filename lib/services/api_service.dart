import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Базовый адрес вашего сервера на Render
  static const String baseUrl = 'https://gid-backend-oi81.onrender.com';

  /// Преобразует относительную ссылку на аудиофайл (/static/...) в полный URL
  static String? formatAudioUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$baseUrl$cleanPath';
  }

  /// Проверка связи с бэкендом (GET /health)
  static Future<bool> pingServer() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Главный метод общения с ИИ-гидом (POST /api/v1/ask-guide)
  static Future<Map<String, dynamic>> askGuide({
    double? lat,
    double? lng,
    String guideId = 'alexander',
    String? question,
    String? poiId,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/ask-guide');

    final Map<String, dynamic> bodyData = {
      'guide_id': guideId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (question != null && question.isNotEmpty) 'question': question,
      if (poiId != null) 'poi_id': poiId,
    };

    try {
      debugPrint('Отправка запроса к гиду: $url');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
      } else {
        debugPrint('Ошибка ask-guide: Код ${response.statusCode}, Тело: ${response.body}');
      }
    } catch (e) {
      debugPrint('Исключение при вызове ask-guide: $e');
    }

    return {
      'text': 'Не удалось получить ответ от гида. Убедитесь, что бэкенд на Render активен.',
      'audio_url': null,
    };
  }

  /// Генерация рассказа гида по координатам
  static Future<Map<String, dynamic>> generateGuideStory({
    required double lat,
    required double lng,
    required String guideId,
  }) async {
    return askGuide(
      lat: lat,
      lng: lng,
      guideId: guideId,
      question: 'Расскажи, что интересного находится рядом со мной.',
    );
  }

  /// Получение ближайших POI (GET /api/v1/nearby)
  static Future<List<dynamic>> fetchNearbyPois({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/nearby?lat=$lat&lng=$lng&radius=$radiusKm');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('items')) return data['items'] as List;
      }
    } catch (e) {
      debugPrint('Ошибка получения ближайших POI: $e');
    }

    return [];
  }

  /// Загрузка списка POI (fallback)
  static Future<List<dynamic>> fetchPois() async {
    return fetchNearbyPois(lat: 59.2205, lng: 39.8915);
  }

  /// Распознавание изображения с камеры (AI Vision)
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/api/v1/ask-guide');

    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
      }
    } catch (e) {
      debugPrint('Ошибка отправки изображения: $e');
    }

    return {
      'description': 'Не удалось распознать объект.',
      'audio_url': null,
    };
  }
}
