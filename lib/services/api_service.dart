import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://gid-backend-oi81.onrender.com';

  static Future<Map<String, dynamic>> generateGuideStory({
    required double lat,
    required double lng,
    required String guideId,
  }) async {
    // Сначала пробуем роут /api/generate
    final urlGenerate = Uri.parse('$baseUrl/api/generate');
    try {
      final response = await http.post(
        urlGenerate,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
          'guide_id': guideId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      // Игнорируем и идем в резервный эндпоинт
    }

    // Если /api/generate вернул 404 или ошибку, отправляем в /api/ask
    return await askGuide(
      question: "Расскажи, что интересного находится вокруг меня.",
      guideId: guideId,
      lat: lat,
      lng: lng,
    );
  }

  static Future<Map<String, dynamic>> askGuide({
    String? question,
    String guideId = 'alexander',
    String? poiId,
    double? lat,
    double? lng,
  }) async {
    final url = Uri.parse('$baseUrl/api/ask');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question ?? 'Расскажи об этом месте',
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
