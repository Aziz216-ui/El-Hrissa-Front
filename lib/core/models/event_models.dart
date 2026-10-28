class EventResponse {
  final int id;
  final String name;
  final String? description;
  final String? venueName;
  final double? latitude;
  final double? longitude;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? createdByUserId;
  final int attendeeCount;

  EventResponse({
    required this.id,
    required this.name,
    this.description,
    this.venueName,
    this.latitude,
    this.longitude,
    this.startsAt,
    this.endsAt,
    this.createdByUserId,
    required this.attendeeCount,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      venueName: json['venueName'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'])?.toLocal()
          : null,
      endsAt:
          json['endsAt'] != null ? DateTime.tryParse(json['endsAt'])?.toLocal() : null,
      createdByUserId: json['createdByUserId'],
      attendeeCount: json['attendeeCount'] ?? 0,
    );
  }
}
