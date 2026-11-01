/// Ce que l'utilisateur peut faire d'un événement.
enum EventAction {
  /// Il existe une page de réservation (billetterie) : on l'ouvre.
  book,

  /// Événement créé dans l'app : l'inscription se fait dans l'app.
  register,

  /// Ni réservation ni inscription : l'événement est seulement une idée de sortie.
  suggestion,
}

/// Types d'événements, tels que le serveur les renvoie (code) et tels qu'on les affiche.
const eventCategoryLabels = <String, String>{
  'THEATRE': 'Théâtre',
  'CONCERT': 'Concert',
  'FESTIVAL': 'Festival',
  'HUMOUR': 'Humour',
  'CINEMA': 'Cinéma',
  'EXPO': 'Exposition',
  'SPORT': 'Sport',
  'SOIREE': 'Soirée',
  'ATELIER': 'Atelier',
  'AUTRE': 'Autre',
};

String eventCategoryLabel(String code) => eventCategoryLabels[code] ?? code;

class EventResponse {
  final int id;
  final String name;
  final String? description;
  final String? venueName;
  final String? city;
  final String? category;
  final String? sourceUrl;
  final String? priceText;
  final double? latitude;
  final double? longitude;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? createdByUserId;
  final int attendeeCount;

  /// Nombre de places (null = illimité) et places restantes.
  final int? capacity;
  final int? spotsLeft;

  /// Personnes sur liste d'attente (renseigné seulement pour l'organisateur).
  final int? waitlistCount;

  EventResponse({
    required this.id,
    required this.name,
    this.description,
    this.venueName,
    this.city,
    this.category,
    this.sourceUrl,
    this.priceText,
    this.latitude,
    this.longitude,
    this.startsAt,
    this.endsAt,
    this.createdByUserId,
    required this.attendeeCount,
    this.capacity,
    this.spotsLeft,
    this.waitlistCount,
  });

  /// Toutes les places sont prises : on s'inscrit sur liste d'attente.
  bool get isFull => capacity != null && (spotsLeft ?? 1) <= 0;

  bool get hasEnded {
    final start = startsAt;
    if (start == null) return false;
    return (endsAt ?? start.add(const Duration(hours: 4))).isBefore(DateTime.now());
  }

  bool get hasBookingLink => sourceUrl != null && sourceUrl!.trim().isNotEmpty;

  /// Réservation externe si un lien existe, inscription dans l'app pour les événements créés
  /// dans l'app, sinon simple suggestion.
  EventAction get action {
    if (hasBookingLink) return EventAction.book;
    if (createdByUserId != null) return EventAction.register;
    return EventAction.suggestion;
  }

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      venueName: json['venueName'],
      city: json['city'],
      category: json['category'],
      sourceUrl: json['sourceUrl'],
      priceText: json['priceText'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'])?.toLocal()
          : null,
      endsAt:
          json['endsAt'] != null ? DateTime.tryParse(json['endsAt'])?.toLocal() : null,
      createdByUserId: json['createdByUserId'],
      attendeeCount: json['attendeeCount'] ?? 0,
      capacity: json['capacity'],
      spotsLeft: json['spotsLeft'],
      waitlistCount: json['waitlistCount'],
    );
  }
}

/// Villes et types proposés dans les filtres.
class EventFilters {
  final List<String> cities;
  final List<String> categories;
  const EventFilters({this.cities = const [], this.categories = const []});

  bool get isEmpty => cities.isEmpty && categories.isEmpty;

  factory EventFilters.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic raw) => (raw as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return EventFilters(cities: strings(json['cities']), categories: strings(json['categories']));
  }
}

/// Page publique d'un organisateur.
class OrganizerResponse {
  final int userId;
  final String displayName;
  final int eventsCount;
  final int participantsCount;
  final List<EventResponse> upcomingEvents;

  OrganizerResponse({
    required this.userId,
    required this.displayName,
    required this.eventsCount,
    required this.participantsCount,
    required this.upcomingEvents,
  });

  factory OrganizerResponse.fromJson(Map<String, dynamic> json) {
    return OrganizerResponse(
      userId: json['userId'] ?? 0,
      displayName: json['displayName'] ?? '',
      eventsCount: (json['eventsCount'] as num?)?.toInt() ?? 0,
      participantsCount: (json['participantsCount'] as num?)?.toInt() ?? 0,
      upcomingEvents: ((json['upcomingEvents'] as List<dynamic>?) ?? []).map((e) => EventResponse.fromJson(e)).toList(),
    );
  }
}
