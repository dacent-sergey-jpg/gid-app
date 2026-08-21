import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/poi_model.dart';

class ApiService {
  static const String baseUrl = 'https://gid-backend-oi81.onrender.com';

  /// Получение списка близлежащих мест (POI)
  static Future<List<PoiModel>> getNearbyPois({
    required double lat,
    required double lon,
    double radiusMeters = 5000.0,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius_meters': radiusMeters.toString(),
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => PoiModel.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки POI: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService error (getNearbyPois): $e');
      rethrow;
    }
  }

  /// Задать вопрос гиду (RAG / AI)
  static Future<Map<String, dynamic>> askGuide({
    required String poiId,
    String? userQuestion,
    String? question,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/ask-guide');
    final actualQuestion = userQuestion ?? question ?? '';

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'poi_id': poiId,
          'user_question': actualQuestion,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        throw Exception('Ошибка при вопросе гиду: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService error (askGuide): $e');
      rethrow;
    }
  }

  /// Распознавание фото через AI Vision
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final uri = Uri.parse('$baseUrl/api/v1/analyze-image');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        throw Exception('Ошибка анализа изображения: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService error (analyzeImage): $e');
      rethrow;
    }
  }

  /// Форматирование URL аудиозаписи
  static String? formatAudioUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    return '$baseUrl$rawUrl';
  }
}
