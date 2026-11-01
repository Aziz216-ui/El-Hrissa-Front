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

/// Chiffres globaux renvoyés par GET /api/stats.
class AppStats {
  final int totalUsers;
  final int emailVerifiedUsers;
  final int menCount;
  final int womenCount;
  final int newProfilesLast7Days;
  final int verificationPending;
  final int verificationApproved;
  final int verificationRejected;
  final int verificationNotSubmitted;
  final int totalMatches;
  final int matchesLast7Days;
  final int totalMessages;
  final int messagesLast7Days;
  final int totalEvents;
  final int upcomingEvents;
  final int reportsPending;
  final int reportsTotal;

  AppStats.fromJson(Map<String, dynamic> j)
      : totalUsers = (j['totalUsers'] ?? 0) as int,
        emailVerifiedUsers = (j['emailVerifiedUsers'] ?? 0) as int,
        menCount = (j['menCount'] ?? 0) as int,
        womenCount = (j['womenCount'] ?? 0) as int,
        newProfilesLast7Days = (j['newProfilesLast7Days'] ?? 0) as int,
        verificationPending = (j['verificationPending'] ?? 0) as int,
        verificationApproved = (j['verificationApproved'] ?? 0) as int,
        verificationRejected = (j['verificationRejected'] ?? 0) as int,
        verificationNotSubmitted = (j['verificationNotSubmitted'] ?? 0) as int,
        totalMatches = (j['totalMatches'] ?? 0) as int,
        matchesLast7Days = (j['matchesLast7Days'] ?? 0) as int,
        totalMessages = (j['totalMessages'] ?? 0) as int,
        messagesLast7Days = (j['messagesLast7Days'] ?? 0) as int,
        totalEvents = (j['totalEvents'] ?? 0) as int,
        upcomingEvents = (j['upcomingEvents'] ?? 0) as int,
        reportsPending = (j['reportsPending'] ?? 0) as int,
        reportsTotal = (j['reportsTotal'] ?? 0) as int;
}
