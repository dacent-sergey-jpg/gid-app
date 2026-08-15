import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
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

    // Пробуем несколько возможных роутов сервера
    final endpoints = ['/api/generate', '/generate', '/api/ask', '/ask'];

    for (final path in endpoints) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyData),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
        }
      } catch (e) {
        debugPrint('Ошибка вызова $path: $e');
      }
    }

    throw Exception('Не удалось получить ответ гида (ошибка сервера)');
  }

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
        final response = await http.post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyData),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
        }
      } catch (e) {
        debugPrint('Ошибка запроса к $path: $e');
      }
    }

    throw Exception('Сервер не отвечает на вопрос гиду (ошибка 404)');
  }

  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final endpoints = ['/api/vision', '/vision', '/api/recognize', '/recognize'];

    for (final path in endpoints) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
        }
      } catch (e) {
        debugPrint('Ошибка отправки снимка в $path: $e');
      }
    }

    throw Exception('Ошибка распознавания снимка');
  }

  static Future<List<dynamic>> fetchPois() async {
    final endpoints = ['/api/pois', '/pois'];

    for (final path in endpoints) {
      try {
        final response = await http.get(Uri.parse('$baseUrl$path'));
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
