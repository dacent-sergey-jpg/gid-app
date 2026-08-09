import 'dart:convert';
import 'package:http/http.dart' as http;

class PoiModel {
  final int id;
  final String title;
  final String description;
  final double lat;
  final double lon;
  final String audioUrl;
  final double distanceMeters;

  PoiModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lon,
    required this.audioUrl,
    required this.distanceMeters,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      audioUrl: json['audio_url'] as String,
      distanceMeters: (json['distance_meters'] as num).toDouble(),
    );
  }
}

class ApiService {
  static const String _baseUrl = 'https://gid-backend-oi81.onrender.com';

  static Future<List<PoiModel>> fetchNearbyPoi({
    required double lat,
    required double lon,
    double radiusMeters = 5000.0,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/api/v1/nearby?lat=$lat&lon=$lon&radius_meters=$radiusMeters',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> data = body['data'];
      return data.map((json) => PoiModel.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }
}
