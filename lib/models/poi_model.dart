class PoiModel {
  final int id;
  final String title;
  final String description;
  final double lat;
  final double lon;
  final String? category;
  final String? audioUrl;
  final String? imageUrl;
  final List<String> facts;
  final double distanceMeters;

  PoiModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lon,
    this.category,
    this.audioUrl,
    this.imageUrl,
    this.facts = const [],
    this.distanceMeters = 0.0,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? 'Без названия',
      description: json['description'] ?? '',
      lat: ((json['latitude'] ?? json['lat']) as num).toDouble(),
      lon: ((json['longitude'] ?? json['lon']) as num).toDouble(),
      category: json['category'],
      audioUrl: json['audio_url'],
      imageUrl: json['image_url'],
      facts: json['facts'] != null ? List<String>.from(json['facts']) : [],
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lat': lat,
      'lon': lon,
      'category': category,
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'facts': facts,
      'distance_meters': distanceMeters,
    };
  }
}
