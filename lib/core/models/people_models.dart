import '../api/endpoints.dart';
import 'profile_models.dart';

/// Où en est la relation avec une personne trouvée par son nom.
enum PersonRelation {
  none,
  requestSent,
  requestReceived,
  matched;

  static PersonRelation parse(String? raw) {
    switch (raw) {
      case 'REQUEST_SENT':
        return PersonRelation.requestSent;
      case 'REQUEST_RECEIVED':
        return PersonRelation.requestReceived;
      case 'MATCHED':
        return PersonRelation.matched;
      default:
        return PersonRelation.none;
    }
  }
}

/// Une personne trouvée par son nom : prénom, initiale, âge, photo.
class PersonSearchResult {
  final int userId;
  final String displayName;
  final int? age;
  final String? photoUrl;
  final PersonRelation relation;
  final int? matchId;

  const PersonSearchResult({
    required this.userId,
    required this.displayName,
    this.age,
    this.photoUrl,
    this.relation = PersonRelation.none,
    this.matchId,
  });

  PersonSearchResult copyWith({PersonRelation? relation, int? matchId}) => PersonSearchResult(
        userId: userId,
        displayName: displayName,
        age: age,
        photoUrl: photoUrl,
        relation: relation ?? this.relation,
        matchId: matchId ?? this.matchId,
      );

  factory PersonSearchResult.fromJson(Map<String, dynamic> json) {
    final photo = json['photoUrl'] as String?;
    return PersonSearchResult(
      userId: json['userId'] ?? 0,
      displayName: json['displayName'] ?? '',
      age: json['age'],
      photoUrl: photo == null || photo.isEmpty ? null : Endpoints.resolveUrl(photo),
      relation: PersonRelation.parse(json['relation']),
      matchId: json['matchId'],
    );
  }
}

/// Une demande de contact reçue.
class ConnectionRequest {
  final PublicProfileResponse profile;
  final DateTime? requestedAt;

  const ConnectionRequest({required this.profile, this.requestedAt});

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) {
    return ConnectionRequest(
      profile: PublicProfileResponse.fromJson(json['profile'] ?? {}),
      requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt'])?.toLocal() : null,
    );
  }
}

/// Résultat d'une demande envoyée ou acceptée.
class RequestResult {
  /// 'SENT' (demande envoyée) ou 'MATCHED' (la conversation existe).
  final String status;
  final int? matchId;

  const RequestResult({required this.status, this.matchId});

  bool get matched => status == 'MATCHED';

  factory RequestResult.fromJson(Map<String, dynamic> json) =>
      RequestResult(status: json['status'] ?? 'SENT', matchId: json['matchId']);
}
