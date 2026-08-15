import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base backend URL hosted on Render
  static const String baseUrl = 'https://gid-backend-oi81.onrender.com';

  /// Converts relative audio paths (/static/...) to full absolute URLs
  static String? formatAudioUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$baseUrl$cleanPath';
  }

  /// Server health check (GET /health)
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

  /// Primary method to query AI guide with location & question payload
  static Future<Map<String, dynamic>> askGuide({
    double? lat,
    double? lng,
    String guideId = 'alexander',
    String? question,
    String? poiId,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/ask-guide');

    final double safeLat = lat ?? 59.2205; // Default coordinates (Vologda)
    final double safeLng = lng ?? 39.8915;
    final String promptText = (question != null && question.isNotEmpty)
        ? question
        : 'Расскажи подробнее об этом месте.';

    // Clean primary payload matching exact FastAPI Pydantic schema required by backend
    final Map<String, dynamic> primaryBody = {
      'guide_id': guideId,
      'user_question': promptText,
      'question': promptText,
      'poi_id': (poiId != null && poiId.isNotEmpty) ? poiId : '0',
      'latitude': safeLat,
      'longitude': safeLng,
      'lat': safeLat,
      'lng': safeLng,
    };

    try {
      debugPrint('Sending ask-guide request to: $url with body: ${jsonEncode(primaryBody)}');
      var response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(primaryBody),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 422) {
        debugPrint('Primary request failed with 422. Retrying with numeric poi_id fallback...');
        final Map<String, dynamic> fallbackBody = {
          'guide_id': guideId,
          'user_question': promptText,
          'question': promptText,
          'poi_id': int.tryParse(poiId ?? '0') ?? 0,
          'latitude': safeLat,
          'longitude': safeLng,
          'lat': safeLat,
          'lng': safeLng,
        };
        response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(fallbackBody),
            )
            .timeout(const Duration(seconds: 30));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) return data;
      } else {
        String detailedError = 'Ошибка сервера (${response.statusCode})';
        try {
          final errBody = utf8.decode(response.bodyBytes);
          debugPrint('FastAPI Error response: $errBody');
          final errJson = jsonDecode(errBody);
          if (errJson is Map && errJson.containsKey('detail')) {
            final detail = errJson['detail'];
            if (detail is List) {
              final missingFields = detail.map((e) {
                if (e is Map && e.containsKey('loc')) {
                  final locList = (e['loc'] as List).where((p) => p != 'body').join('.');
                  final msg = e['msg'] ?? '';
                  return '$locList: $msg';
                }
                return e.toString();
              }).join(', ');
              detailedError = 'Ошибка схемы Pydantic (422): [$missingFields]';
            } else {
              detailedError = 'Ошибка (422): ${detail.toString()}';
            }
          }
        } catch (_) {}

        return {
          'text': detailedError,
          'audio_url': null,
        };
      }
    } catch (e) {
      debugPrint('Exception calling ask-guide: $e');
      return {
        'text': 'Ошибка соединения с сервером: $e',
        'audio_url': null,
      };
    }

    return {
      'text': 'Не удалось получить ответ от сервера.',
      'audio_url': null,
    };
  }

  /// Generate story based on user's current coordinates
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

  /// Fetch POIs within specified radius (GET /api/v1/nearby)
  static Future<List<dynamic>> fetchNearbyPois({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/nearby?lat=$lat&lng=$lng&radius=$radiusKm');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) return data;
        if (data is Map && data.containsKey('items')) return data['items'] as List;
      }
    } catch (e) {
      debugPrint('Error fetching nearby POIs: $e');
    }

    return [];
  }

  /// Recognize object via camera image upload (AI Vision)
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/api/v1/analyze-image');

    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) return data;
      } else {
        debugPrint('Vision API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }

    return {
      'description': 'Не удалось распознать объект.',
      'audio_url': null,
    };
  }
}
