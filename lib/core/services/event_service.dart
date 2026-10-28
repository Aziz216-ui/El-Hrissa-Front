import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../models/event_models.dart';
import '../models/profile_models.dart';

class EventService {
  final ApiClient _api = ApiClient();

  Future<List<EventResponse>> getEvents({bool upcomingOnly = true, int page = 0, int size = 50}) async {
    try {
      final response = await _api.dio.get(
        Endpoints.events,
        queryParameters: {'upcomingOnly': upcomingOnly, 'page': page, 'size': size},
      );
      final List<dynamic> content = response.data['content'] ?? [];
      return content.map((e) => EventResponse.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger les événements'));
    }
  }

  Future<Set<int>> getJoinedEventIds() async {
    try {
      final response = await _api.dio.get(Endpoints.joinedEvents);
      return (response.data as List<dynamic>).map((e) => (e as num).toInt()).toSet();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger vos inscriptions'));
    }
  }

  Future<List<PublicProfileResponse>> getAttendees(int eventId) async {
    try {
      final response = await _api.dio.get(Endpoints.eventAttendees(eventId));
      return (response.data as List<dynamic>).map((p) => PublicProfileResponse.fromJson(p)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger les participants'));
    }
  }

  Future<void> joinEvent(int eventId) async {
    try {
      await _api.dio.post(Endpoints.joinEvent(eventId));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Erreur lors de l'inscription à l'événement"));
    }
  }

  Future<void> leaveEvent(int eventId) async {
    try {
      await _api.dio.delete(Endpoints.leaveEvent(eventId));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Erreur lors du désistement'));
    }
  }

  /// Réservé aux organisateurs.
  Future<EventResponse> createEvent({
    required String name,
    String? description,
    String? venueName,
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    try {
      final response = await _api.dio.post(Endpoints.events, data: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (venueName != null && venueName.isNotEmpty) 'venueName': venueName,
        'startsAt': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
      });
      return EventResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible de créer l'événement"));
    }
  }

  Future<void> deleteEvent(int eventId) async {
    try {
      await _api.dio.delete(Endpoints.eventDetails(eventId));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible de supprimer l'événement"));
    }
  }
}
