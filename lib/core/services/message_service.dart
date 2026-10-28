import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../models/message_models.dart';

class MessageService {
  final ApiClient _api = ApiClient();

  /// Messages triés du plus récent au plus ancien (page 0 = les derniers).
  Future<List<MessageResponse>> getMessages(int matchId, {int page = 0, int size = 50}) async {
    try {
      final response = await _api.dio.get(
        Endpoints.matchMessages(matchId),
        queryParameters: {'page': page, 'size': size},
      );
      final List<dynamic> content = response.data['content'] ?? [];
      return content.map((m) => MessageResponse.fromJson(m)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger les messages'));
    }
  }

  Future<MessageResponse> sendMessage(int matchId, String content) async {
    try {
      final response = await _api.dio.post(
        Endpoints.matchMessages(matchId),
        data: {'content': content.trim()},
      );
      return MessageResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Erreur d'envoi du message"));
    }
  }
}
