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

    // Flexible payload structure to support all variations of FastAPI Pydantic schemas
    final Map<String, dynamic> bodyData = {
      'guide_id': guideId,
      'guide': guideId,
      if (lat != null) 'lat': lat,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'lng': lng,
      if (lng != null) 'longitude': lng,
      'question': (question != null && question.isNotEmpty)
          ? question
          : 'Расскажи подробнее об этом месте.',
      if (poiId != null) 'poi_id': poiId,
    };

    try {
      debugPrint('Sending ask-guide request to: $url');
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
        debugPrint('Error ask-guide: Code ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception calling ask-guide: $e');
    }

    return {
      'text': 'Не удалось получить ответ от гида. Убедитесь, что бэкенд на Render активен.',
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
        final data = jsonDecode(response.body);
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
      debugPrint('Error uploading image: $e');
    }

    return {
      'description': 'Не удалось распознать объект.',
      'audio_url': null,
    };
  }
}
