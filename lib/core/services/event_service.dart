import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../models/event_models.dart';
import '../models/profile_models.dart';

class EventService {
  final ApiClient _api = ApiClient();

  /// Villes et types des événements à venir. Un serveur plus ancien n'a pas cette route :
  /// on renvoie alors des filtres vides, et l'écran les masque.
  Future<EventFilters> getFilters() async {
    try {
      final response = await _api.dio.get('/api/events/filters');
      return EventFilters.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return const EventFilters();
    }
  }

  Future<List<EventResponse>> getEvents({
    bool upcomingOnly = true,
    int page = 0,
    int size = 50,
    String? city,
    String? category,
  }) async {
    try {
      final response = await _api.dio.get(
        Endpoints.events,
        queryParameters: {
          'upcomingOnly': upcomingOnly,
          'page': page,
          'size': size,
          if (city != null && city.isNotEmpty) 'city': city,
          if (category != null && category.isNotEmpty) 'category': category,
        },
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

  /// Événements où je suis sur liste d'attente (un serveur plus ancien n'a pas cette route : liste vide).
  Future<Set<int>> getWaitlistedEventIds() async {
    try {
      final response = await _api.dio.get('/api/events/waitlisted');
      return (response.data as List<dynamic>).map((e) => (e as num).toInt()).toSet();
    } on DioException {
      return {};
    }
  }

  /// Pour chaque événement, le nombre de participants qui pourraient me plaire. Facultatif : vide en cas d'erreur.
  Future<Map<int, int>> getCompatibleCounts(List<int> eventIds) async {
    if (eventIds.isEmpty) return {};
    try {
      final response = await _api.dio.get('/api/events/compatible', queryParameters: {'ids': eventIds.join(',')});
      return (response.data as Map<String, dynamic>).map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
    } on DioException {
      return {};
    }
  }

  /// Événements terminés depuis moins de 48 h où j'avais une place (« Tu as croisé qui ? »).
  Future<List<EventResponse>> getCrossedEvents() async {
    try {
      final response = await _api.dio.get('/api/events/crossed');
      return (response.data as List<dynamic>).map((e) => EventResponse.fromJson(e)).toList();
    } on DioException {
      return [];
    }
  }

  /// Espace organisateur : mes événements, passés et à venir.
  Future<List<EventResponse>> getMyEvents() async {
    try {
      final response = await _api.dio.get('/api/events/mine');
      return (response.data as List<dynamic>).map((e) => EventResponse.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger vos événements'));
    }
  }

  Future<OrganizerResponse> getOrganizer(int userId) async {
    try {
      final response = await _api.dio.get('/api/organizers/$userId');
      return OrganizerResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible de charger la page de l'organisateur"));
    }
  }

  /// Renvoie true si l'événement est complet : la personne est alors sur liste d'attente.
  Future<bool> joinEvent(int eventId) async {
    try {
      final response = await _api.dio.post(Endpoints.joinEvent(eventId));
      final data = response.data;
      return data is Map && data['status'] == 'WAITLISTED';
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
    String? city,
    String? category,
    required DateTime startsAt,
    DateTime? endsAt,
    int? capacity,
    double? latitude,
    double? longitude,
    int? eventId,
  }) async {
    final body = {
      'name': name,
      if (city != null && city.isNotEmpty) 'city': city,
      if (category != null && category.isNotEmpty) 'category': category,
      if (description != null && description.isNotEmpty) 'description': description,
      if (venueName != null && venueName.isNotEmpty) 'venueName': venueName,
      'startsAt': startsAt.toUtc().toIso8601String(),
      if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
      if (capacity != null) 'capacity': capacity,
      // Une modification remplace tout : sans ces deux valeurs, la position de l'événement serait effacée
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    try {
      final response = eventId == null
          ? await _api.dio.post(Endpoints.events, data: body)
          : await _api.dio.put(Endpoints.eventDetails(eventId), data: body);
      return EventResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, eventId == null ? "Impossible de créer l'événement" : "Impossible de modifier l'événement"));
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
