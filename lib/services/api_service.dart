import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Продакшн URL вашего сервера на Render
  static const String baseUrl = 'https://gid-backend-oi81.onrender.com';

  /// Запрос к Yandex AI на генерацию рассказа гида
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
}
