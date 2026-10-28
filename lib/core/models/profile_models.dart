import '../api/endpoints.dart';

class PhotoResponse {
  final int id;
  final String url;
  final bool isMain;

  PhotoResponse({required this.id, required this.url, required this.isMain});

  factory PhotoResponse.fromJson(Map<String, dynamic> json) {
    return PhotoResponse(
      id: json['id'] ?? 0,
      url: Endpoints.resolveUrl(json['url'] ?? ''),
      // Jackson sérialise le champ booléen "main"
      isMain: json['main'] ?? json['isMain'] ?? false,
    );
  }
}

List<PhotoResponse> _parsePhotos(dynamic raw) =>
    (raw as List<dynamic>?)?.map((p) => PhotoResponse.fromJson(p)).toList() ?? [];

List<String> _parseInterests(dynamic raw) =>
    (raw as List<dynamic>?)?.map((i) => i.toString()).toList() ?? [];

/// URL de la photo principale, ou null si le profil n'a aucune photo.
String? _mainPhotoUrl(List<PhotoResponse> photos) {
  if (photos.isEmpty) return null;
  final main = photos.where((p) => p.isMain);
  return (main.isNotEmpty ? main.first : photos.first).url;
}

class PublicProfileResponse {
  final int userId;
  final String displayName;
  final String? bio;
  final int? age;
  final String? gender;
  final List<PhotoResponse> photos;
  final List<String> interests;

  PublicProfileResponse({
    required this.userId,
    required this.displayName,
    this.bio,
    this.age,
    this.gender,
    required this.photos,
    required this.interests,
  });

  factory PublicProfileResponse.fromJson(Map<String, dynamic> json) {
    return PublicProfileResponse(
      userId: json['userId'] ?? 0,
      displayName: json['displayName'] ?? '',
      bio: json['bio'],
      age: json['age'],
      gender: json['gender'],
      photos: _parsePhotos(json['photos']),
      interests: _parseInterests(json['interests']),
    );
  }

  String? get mainPhotoUrl => _mainPhotoUrl(photos);
}

class ProfileResponse {
  final int id;
  final int userId;
  final String? displayName;
  final String? bio;
  final int? age;
  final String? gender;
  final String? genderPreference;
  final double? latitude;
  final double? longitude;
  final bool complete;
  final bool emailVerified;
  final String? verificationStatus;
  final List<PhotoResponse> photos;
  final List<String> interests;

  ProfileResponse({
    required this.id,
    required this.userId,
    this.displayName,
    this.bio,
    this.age,
    this.gender,
    this.genderPreference,
    this.latitude,
    this.longitude,
    this.complete = false,
    this.emailVerified = false,
    this.verificationStatus,
    required this.photos,
    required this.interests,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      displayName: json['displayName'],
      bio: json['bio'],
      age: json['age'],
      gender: json['gender'],
      genderPreference: json['genderPreference'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      complete: json['complete'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      verificationStatus: json['verificationStatus'],
      photos: _parsePhotos(json['photos']),
      interests: _parseInterests(json['interests']),
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
  bool get isVerified => verificationStatus == 'VERIFIED' || verificationStatus == 'APPROVED';
  String? get mainPhotoUrl => _mainPhotoUrl(photos);
}
