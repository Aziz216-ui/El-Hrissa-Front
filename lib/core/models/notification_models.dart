class NotificationResponse {
  final int id;
  final String type;
  final int? referenceId;
  final String content;
  final bool read;
  final DateTime? createdAt;

  NotificationResponse({
    required this.id,
    required this.type,
    this.referenceId,
    required this.content,
    required this.read,
    this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      referenceId: json['referenceId'],
      content: json['content'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'])?.toLocal() : null,
    );
  }
}

class BlockedUser {
  final int userId;
  final String nom;
  final String prenom;

  BlockedUser({required this.userId, required this.nom, required this.prenom});

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        userId: json['userId'] ?? 0,
        nom: json['nom'] ?? '',
        prenom: json['prenom'] ?? '',
      );

  String get fullName => '$prenom $nom'.trim();
}
