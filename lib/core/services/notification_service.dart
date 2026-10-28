import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../models/notification_models.dart';

class NotificationService {
  final ApiClient _api = ApiClient();

  Future<List<NotificationResponse>> getNotifications({int page = 0, int size = 30}) async {
    try {
      final response = await _api.dio.get(
        Endpoints.notifications,
        queryParameters: {'page': page, 'size': size},
      );
      final List<dynamic> content = response.data['content'] ?? [];
      return content.map((n) => NotificationResponse.fromJson(n)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger les notifications'));
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _api.dio.get(Endpoints.unreadCount);
      final data = response.data;
      if (data is Map && data.isNotEmpty) {
        return (data.values.first as num).toInt();
      }
      return 0;
    } on DioException {
      return 0;
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.dio.put(Endpoints.readNotification(id));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Erreur'));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.dio.put(Endpoints.readAllNotifications);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Erreur'));
    }
  }
}
