import 'profile_models.dart';

class CandidateResponse {
  final PublicProfileResponse profile;
  final double? distanceKm;

  CandidateResponse({required this.profile, this.distanceKm});

  factory CandidateResponse.fromJson(Map<String, dynamic> json) {
    return CandidateResponse(
      profile: PublicProfileResponse.fromJson(json['profile'] ?? {}),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

class SwipeRequest {
  final int targetUserId;
  final bool liked;

  SwipeRequest({required this.targetUserId, required this.liked});

  Map<String, dynamic> toJson() => {
        'targetUserId': targetUserId,
        'liked': liked,
      };
}

class SwipeResponse {
  final bool liked;
  final bool matched;
  final int? matchId;

  SwipeResponse({
    required this.liked,
    required this.matched,
    this.matchId,
  });

  factory SwipeResponse.fromJson(Map<String, dynamic> json) {
    return SwipeResponse(
      liked: json['liked'] ?? false,
      matched: json['matched'] ?? false,
      matchId: json['matchId'],
    );
  }
}

class MatchResponse {
  final int matchId;
  final PublicProfileResponse profile;
  final DateTime? matchedAt;

  MatchResponse({
    required this.matchId,
    required this.profile,
    this.matchedAt,
  });

  factory MatchResponse.fromJson(Map<String, dynamic> json) {
    return MatchResponse(
      matchId: json['matchId'] ?? 0,
      profile: PublicProfileResponse.fromJson(json['profile'] ?? {}),
      matchedAt: json['matchedAt'] != null
          ? DateTime.tryParse(json['matchedAt'])?.toLocal()
          : null,
    );
  }
}
