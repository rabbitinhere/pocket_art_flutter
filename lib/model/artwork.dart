class Artwork {
  final int objectID;
  final String title;
  final String primaryImage;
  final String primaryImageSmall;
  final String artistDisplayName;
  final String objectDate;
  final String medium;
  final String dimensions;
  final String culture;

  Artwork({
    this.objectID = 0,
    this.title = '',
    this.primaryImage = '',
    this.primaryImageSmall = '',
    this.artistDisplayName = '',
    this.objectDate = '',
    this.medium = '',
    this.dimensions = '',
    this.culture = '',
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      objectID: json['objectID'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      primaryImage: json['primaryImage'] ?? '',
      primaryImageSmall: json['primaryImageSmall'] ?? '',
      artistDisplayName: json['artistDisplayName'] ?? 'Unknown Artist',
      objectDate: json['objectDate'] ?? '',
      medium: json['medium'] ?? '',
      dimensions: json['dimensions'] ?? '',
      culture: json['culture'] ?? '',
    );
  }
}

class ArtworkListResp {
  final int total;
  final List<int> objectIDs;

  ArtworkListResp({required this.total, required this.objectIDs});

  factory ArtworkListResp.fromJson(Map<String, dynamic> json) {
    return ArtworkListResp(
      total: json['total'] ?? 0,
      objectIDs: (json['objectIDs'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }
}