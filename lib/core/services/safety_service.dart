import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../models/notification_models.dart';

/// Blocage et signalement d'utilisateurs.
class SafetyService {
  final ApiClient _api = ApiClient();

  Future<void> block(int userId) async {
    try {
      await _api.dio.post(Endpoints.blocks, data: {'userId': userId});
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible de bloquer l'utilisateur"));
    }
  }

  Future<void> unblock(int userId) async {
    try {
      await _api.dio.delete(Endpoints.unblock(userId));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de débloquer'));
    }
  }

  Future<List<BlockedUser>> getBlocked() async {
    try {
      final response = await _api.dio.get(Endpoints.blocks);
      return (response.data as List<dynamic>).map((b) => BlockedUser.fromJson(b)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger la liste'));
    }
  }

  Future<void> report(int userId, String reason, {String? details}) async {
    try {
      await _api.dio.post(Endpoints.reports, data: {
        'reportedUserId': userId,
        'reason': reason,
        if (details != null && details.isNotEmpty) 'details': details,
      });
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de signaler'));
    }
  }
}
