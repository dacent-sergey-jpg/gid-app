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

  PoiModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.audioUrl,
    this.category,
    required this.lat,
    required this.lng,
    this.facts = const [],
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: (json['id'] ?? json['poi_id'] ?? '0').toString(),
      title: json['title'] ?? json['name'] ?? 'Достопримечательность',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['image'],
      audioUrl: json['audio_url'] ?? json['audio'],
      category: json['category'],
      lat: (json['lat'] ?? json['latitude'] ?? 59.2205).toDouble(),
      lng: (json['lng'] ?? json['longitude'] ?? 39.8915).toDouble(),
      facts: json['facts'] != null ? List<String>.from(json['facts']) : [],
    );
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
    };
  }
}
