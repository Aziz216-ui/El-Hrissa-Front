/// Signalement vu par un modérateur (organisateur).
class ReportItem {
  final int id;
  final int reportedUserId;
  final String reporterName;
  final String reportedName;
  final String reason;
  final String? details;
  final String status; // PENDING | REVIEWED | DISMISSED | ACTION_TAKEN
  final String? moderatorNotes;
  final DateTime? createdAt;

  ReportItem({
    required this.id,
    required this.reportedUserId,
    required this.reporterName,
    required this.reportedName,
    required this.reason,
    this.details,
    required this.status,
    this.moderatorNotes,
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: json['id'] ?? 0,
      reportedUserId: json['reportedUserId'] ?? 0,
      reporterName: json['reporterName'] ?? '',
      reportedName: json['reportedName'] ?? '',
      reason: json['reason'] ?? '',
      details: json['details'],
      status: json['status'] ?? 'PENDING',
      moderatorNotes: json['moderatorNotes'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// Décisions possibles sur un signalement, avec le libellé affiché.
const reportDecisions = <String, String>{
  'DISMISSED': 'Rejeter le signalement',
  'REVIEWED': 'Traité, sans sanction',
  'ACTION_TAKEN': 'Désactiver le compte signalé',
};

String reportStatusLabel(String status) {
  switch (status) {
    case 'PENDING':
      return 'En attente';
    case 'DISMISSED':
      return 'Rejeté';
    case 'REVIEWED':
      return 'Traité';
    case 'ACTION_TAKEN':
      return 'Compte désactivé';
    default:
      return status;
  }
}
