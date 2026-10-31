import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../models/people_models.dart';

/// Chercher une personne par son nom, lui envoyer une demande, répondre aux demandes reçues.
class PeopleService {
  final ApiClient _api = ApiClient();

  Future<List<PersonSearchResult>> search(String query) async {
    try {
      final response = await _api.dio.get('/api/people/search', queryParameters: {'q': query.trim()});
      return (response.data as List<dynamic>).map((p) => PersonSearchResult.fromJson(p)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Recherche impossible pour le moment'));
    }
  }

  Future<RequestResult> sendRequest(int userId) async {
    try {
      final response = await _api.dio.post('/api/people/$userId/request');
      return RequestResult.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'envoyer la demande"));
    }
  }

  Future<List<ConnectionRequest>> getRequests() async {
    try {
      final response = await _api.dio.get('/api/people/requests');
      return (response.data as List<dynamic>).map((r) => ConnectionRequest.fromJson(r)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger les demandes'));
    }
  }

  Future<RequestResult> accept(int userId) async {
    try {
      final response = await _api.dio.post('/api/people/$userId/accept');
      return RequestResult.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'accepter la demande"));
    }
  }

  Future<void> decline(int userId) async {
    try {
      await _api.dio.post('/api/people/$userId/decline');
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de refuser la demande'));
    }
  }
}
