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

  /// Проверка связи с бэкендом (будит спящий сервис на Render)
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

  /// Генерация рассказа гида по координатам (Yandex AI / OpenAI)
  static Future<Map<String, dynamic>> generateGuideStory({
    required double lat,
    required double lng,
    required String guideId,
  }) async {
    final bodyData = {
      'lat': lat,
      'lng': lng,
      'guide_id': guideId,
      'question': 'Расскажи, что интересного находится рядом со мной.',
    };

    final endpoints = ['/api/generate', '/generate', '/api/ask', '/ask'];

    for (final path in endpoints) {
      try {
        debugPrint('Отправка запроса к: $baseUrl$path');
        final response = await http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(bodyData),
            )
            // Увеличиваем таймаут до 45 секунд из-за возможного холодного старта Render
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
        } else {
          debugPrint('Сервер $path вернул код: ${response.statusCode}, тело: ${response.body}');
        }
      } catch (e) {
        debugPrint('Ошибка вызова $path: $e');
      }
    }

    // Возвращаем информативное сообщение вместо молчаливой заглушки
    return {
      'text': 'Не удалось связаться с сервером ИИ. Возможно, сервер Render просыпается или отсутствуют API ключи на бэкенде.',
      'audio_url': null,
    };
  }

  /// Задать произвольный вопрос гиду
  static Future<Map<String, dynamic>> askGuide({
    String? question,
    String guideId = 'alexander',
    String? poiId,
    double? lat,
    double? lng,
  }) async {
    final bodyData = {
      'question': question ?? 'Расскажи об этом месте',
      'guide_id': guideId,
      if (poiId != null) 'poi_id': poiId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    final endpoints = ['/api/ask', '/ask', '/api/generate', '/generate'];

    for (final path in endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(bodyData),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
        }
      } catch (e) {
        debugPrint('Ошибка запроса к $path: $e');
      }
    }

    return {
      'text': 'Сервер ИИ временно недоступен. Проверьте подключение к сети.',
      'audio_url': null,
    };
  }

  /// Распознавание изображения с камеры (AI Vision)
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final endpoints = ['/api/vision', '/vision', '/api/recognize', '/recognize'];

    for (final path in endpoints) {
      try {
        debugPrint('Отправка фото на $baseUrl$path...');
        final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

        final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
        } else {
          debugPrint('Ошибка Vision ($path): код ${response.statusCode}, тело: ${response.body}');
        }
      } catch (e) {
        debugPrint('Ошибка отправки снимка в $path: $e');
      }
    }

    return {
      'description': 'Ошибка AI Vision: Сервер не ответил за 45 секунд. Убедитесь, что бэкенд активен на Render.',
      'audio_url': null,
    };
  }

  /// Загрузка списка POI (достопримечательностей)
  static Future<List<dynamic>> fetchPois() async {
    final endpoints = ['/api/pois', '/pois'];

    for (final path in endpoints) {
      try {
        final response = await http.get(Uri.parse('$baseUrl$path')).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as List<dynamic>;
        }
      } catch (e) {
        debugPrint('Ошибка получения POI из $path: $e');
      }
    }

    return [];
  }
}
