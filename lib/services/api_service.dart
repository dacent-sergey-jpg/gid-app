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

  // Рабочие ссылки на онлайн аудиофайлы для тестирования
  static final List<PoiModel> _fallbackPois = [
    PoiModel(
      id: 1,
      title: 'Софийский собор',
      description: 'Древнейшее сохранившееся каменное здание Вологды, возведенное по повелению Ивана Грозного.',
      lat: 59.2244,
      lon: 39.8837,
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      distanceMeters: 120.0,
    ),
    PoiModel(
      id: 2,
      title: 'Вологодский кремль',
      description: 'Архиерейский двор, ансамбль исторических зданий XVI–XIX веков.',
      lat: 59.2238,
      lon: 39.8831,
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      distanceMeters: 250.0,
    ),
    PoiModel(
      id: 3,
      title: 'Памятник букве «О»',
      description: 'Арт-объект, посвященный характерному вологодскому «окающему» говору.',
      lat: 59.2255,
      lon: 39.8860,
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      distanceMeters: 400.0,
    ),
    PoiModel(
      id: 4,
      title: 'Музей кружева',
      description: 'Уникальный музей, посвященный традиционному вологодскому промыслу.',
      lat: 59.2233,
      lon: 39.8845,
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      distanceMeters: 550.0,
    ),
  ];

  static Future<List<PoiModel>> fetchNearbyPoi({
    required double lat,
    required double lon,
    double radiusMeters = 5000.0,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/api/v1/nearby?lat=$lat&lon=$lon&radius_meters=$radiusMeters',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> data = body['data'];
        return data.map((json) => PoiModel.fromJson(json)).toList();
      }
    } catch (_) {
      // Использование fallback при offline режиме
    }

    return _fallbackPois;
  }
}
