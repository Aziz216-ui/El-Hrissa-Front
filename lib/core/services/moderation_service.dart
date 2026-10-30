import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../models/moderation_models.dart';
import '../models/profile_models.dart';

/// Outils de modération, réservés aux organisateurs (le backend renvoie 403 sinon).
class ModerationService {
  final ApiClient _api = ApiClient();

  Future<List<ReportItem>> getReports({String? status}) async {
    try {
      final response = await _api.dio.get(
        Endpoints.reports,
        queryParameters: {'size': 50, if (status != null) 'status': status},
      );
      final content = (response.data['content'] as List<dynamic>?) ?? [];
      return content.map((r) => ReportItem.fromJson(r)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger les signalements'));
    }
  }

  Future<void> moderateReport(int id, String status, {String? notes}) async {
    try {
      await _api.dio.put(
        Endpoints.moderateReport(id),
        data: {'status': status, if (notes != null && notes.isNotEmpty) 'notes': notes},
      );
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible d\'enregistrer la décision'));
    }
  }

  Future<List<ProfileResponse>> getPendingVerifications() async {
    try {
      final response = await _api.dio.get(Endpoints.pendingVerifications, queryParameters: {'size': 50});
      final content = (response.data['content'] as List<dynamic>?) ?? [];
      return content.map((p) => ProfileResponse.fromJson(p)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger les vérifications'));
    }
  }

  /// Le selfie est privé : on le télécharge avec le jeton, il n'a pas d'URL publique.
  Future<Uint8List> getSelfie(int userId) async {
    try {
      final response = await _api.dio.get<List<int>>(
        Endpoints.verificationSelfie(userId),
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Selfie introuvable'));
    }
  }

  Future<void> reviewVerification(int userId, {required bool approved, String? notes}) async {
    try {
      await _api.dio.put(
        Endpoints.reviewVerification(userId),
        data: {'approved': approved, if (notes != null && notes.isNotEmpty) 'notes': notes},
      );
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible d\'enregistrer la décision'));
    }
  }
}
