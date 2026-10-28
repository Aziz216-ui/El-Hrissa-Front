import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../models/swipe_models.dart';

class SwipeService {
  final ApiClient _api = ApiClient();

  Future<List<CandidateResponse>> getCandidates({
    double? radiusKm,
    int? ageMin,
    int? ageMax,
    int? eventId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _api.dio.get(
        Endpoints.candidates,
        queryParameters: {
          if (radiusKm != null) 'radiusKm': radiusKm,
          if (ageMin != null) 'ageMin': ageMin,
          if (ageMax != null) 'ageMax': ageMax,
          if (eventId != null) 'eventId': eventId,
          'page': page,
          'size': size,
        },
      );
      final List<dynamic> content = response.data['content'] ?? [];
      return content.map((c) => CandidateResponse.fromJson(c)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de récupérer les candidats'));
    }
  }

  Future<SwipeResponse> swipe(int targetUserId, bool liked) async {
    try {
      final response = await _api.dio.post(
        Endpoints.swipe,
        data: {'targetUserId': targetUserId, 'liked': liked},
      );
      return SwipeResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Erreur lors du swipe'));
    }
  }

  Future<List<MatchResponse>> getMyMatches() async {
    try {
      final response = await _api.dio.get(Endpoints.myMatches);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((m) => MatchResponse.fromJson(m)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de récupérer les matchs'));
    }
  }

  Future<void> unmatch(int matchId) async {
    try {
      await _api.dio.delete(Endpoints.unmatch(matchId));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Erreur lors de la suppression du match'));
    }
  }
}
