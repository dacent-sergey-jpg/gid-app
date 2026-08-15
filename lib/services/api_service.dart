import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Продакшн URL вашего сервера на Render
  static const String baseUrl = 'https://gid-backend-oi81.onrender.com';

  /// Запрос к Yandex AI на генерацию рассказа гида по координатам
  static Future<Map<String, dynamic>> generateGuideStory({
    required double lat,
    required double lng,
    required String guideId,
  }) async {
    final url = Uri.parse('$baseUrl/api/generate');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
          'guide_id': guideId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка выполнения запроса generateGuideStory: $e');
      rethrow;
    }
  }

  /// Отправка текстового или голосового вопроса гиду
  static Future<Map<String, dynamic>> askQuestion({
    required String question,
    required String guideId,
  }) async {
    final url = Uri.parse('$baseUrl/api/ask');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'guide_id': guideId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при вопросе гиду: $e');
      rethrow;
    }
  }

  /// Метод askGuide с позиционными аргументами (используется в poi_detail_screen.dart)
  static Future<Map<String, dynamic>> askGuide([
    dynamic p1,
    dynamic p2,
    dynamic p3,
    dynamic p4,
    dynamic p5,
  ]) async {
    final url = Uri.parse('$baseUrl/api/ask');

    String question = '';
    String guideId = 'alexander';
    String? poiId;
    double? lat;
    double? lng;

    if (p1 != null) question = p1.toString();
    if (p2 != null) {
      if (p2 is num) {
        lat = p2.toDouble();
      } else {
        guideId = p2.toString();
      }
    }
    if (p3 != null) {
      if (p3 is num) {
        lng = p3.toDouble();
      } else {
        poiId = p3.toString();
      }
    }
    if (p4 != null && p4 is num) lat = p4.toDouble();
    if (p5 != null && p5 is num) lng = p5.toDouble();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'guide_id': guideId,
          if (poiId != null) 'poi_id': poiId,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при вызове askGuide: $e');
      rethrow;
    }
  }

  /// Отправка фотографии на AI Vision
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/api/vision');
    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка распознавания: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при отправке фото: $e');
      rethrow;
    }
  }

  /// Загрузка списка достопримечательностей
  static Future<List<dynamic>> fetchPois() async {
    final url = Uri.parse('$baseUrl/api/pois');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        return [];
      }
    } catch (e) {
      print('Ошибка получения списка POI: $e');
      return [];
    }
  }
}
