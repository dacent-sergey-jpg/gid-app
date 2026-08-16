import 'dart:convert';

class PoiModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? audioUrl;
  final String? category;
  final double lat;
  final double lng;
  final List<String> facts;
  final double? distance;

  // Геттеры для совместимости с внешними вызовами
  double get latitude => lat;
  double get longitude => lng;

  const PoiModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.audioUrl,
    this.category,
    required this.lat,
    required this.lng,
    this.facts = const [],
    this.distance,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: (json['id'] ?? json['poi_id'] ?? '0').toString(),
      title: json['title'] ?? json['name'] ?? 'Достопримечательность',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['image'],
      audioUrl: json['audio_url'] ?? json['audio'],
      category: json['category'],
      lat: _parseCoordinate(json['lat'] ?? json['latitude'], fallback: 59.2205),
      lng: _parseCoordinate(json['lng'] ?? json['longitude'], fallback: 39.8915),
      facts: json['facts'] is List
          ? List<String>.from((json['facts'] as List).map((e) => e.toString()))
          : const [],
      distance: json['distance'] != null
          ? (num.tryParse(json['distance'].toString())?.toDouble())
          : null,
    );
  }

  static double _parseCoordinate(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'category': category,
      'lat': lat,
      'lng': lng,
      'facts': facts,
      if (distance != null) 'distance': distance,
    };
  }

  // Сериализация в String для сохранения в SharedPreferences
  String toJsonString() => jsonEncode(toJson());

  factory PoiModel.fromJsonString(String source) =>
      PoiModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  // Копирование объекта с изменением отдельных полей
  PoiModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? audioUrl,
    String? category,
    double? lat,
    double? lng,
    List<String>? facts,
    double? distance,
  }) {
    return PoiModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      category: category ?? this.category,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      facts: facts ?? this.facts,
      distance: distance ?? this.distance,
    );
  }

  // Сравнение объектов по id для работы в Set / List (например, в Избранном)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PoiModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
