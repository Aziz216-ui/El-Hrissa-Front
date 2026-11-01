import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../auth/auth_state.dart';
import '../models/organizer_request_models.dart';

/// Devenir organisateur : déposer une demande, suivre son état, et (pour les modérateurs) l'examiner.
class OrganizerRequestService {
  final ApiClient _api = ApiClient();

  Future<OrganizerRequestInfo> submit({
    required String organizationName,
    required String phone,
    String? link,
    required String description,
  }) async {
    try {
      final response = await _api.dio.post('/api/organizer-requests', data: {
        'organizationName': organizationName,
        'phone': phone,
        if (link != null && link.trim().isNotEmpty) 'link': link.trim(),
        'description': description,
      });
      return OrganizerRequestInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'envoyer la demande"));
    }
  }

  /// null si le serveur ne répond pas ou n'a pas encore cette route.
  Future<OrganizerRequestInfo?> getMine() async {
    try {
      final response = await _api.dio.get('/api/organizer-requests/me');
      return OrganizerRequestInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  /// Si le rôle a changé côté serveur (demande acceptée), l'app le prend en compte sans reconnexion.
  Future<OrganizerRequestInfo?> syncRole() async {
    final info = await getMine();
    final role = info?.role;
    if (role != null && role.toUpperCase() != (AuthState.instance.role ?? '').toUpperCase()) {
      await _api.setRole(role);
      AuthState.instance.setRole(role);
    }
    return info;
  }

  Future<List<OrganizerRequestItem>> listPending() async {
    try {
      final response = await _api.dio.get('/api/organizer-requests', queryParameters: {'status': 'PENDING'});
      return (response.data as List<dynamic>).map((e) => OrganizerRequestItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger les demandes'));
    }
  }

  Future<void> approve(int id) async {
    try {
      await _api.dio.post('/api/organizer-requests/$id/approve');
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'accepter la demande"));
    }
  }

  Future<void> reject(int id, String reason) async {
    try {
      await _api.dio.post('/api/organizer-requests/$id/reject', data: {'reason': reason});
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de refuser la demande'));
    }
  }
}
