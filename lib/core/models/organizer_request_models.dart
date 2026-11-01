/// Où en est ma demande pour devenir organisateur (NONE, PENDING, APPROVED, REJECTED) et mon rôle actuel.
class OrganizerRequestInfo {
  final String status;
  final String? organizationName;
  final String? rejectReason;
  final String? role;

  const OrganizerRequestInfo({required this.status, this.organizationName, this.rejectReason, this.role});

  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
  bool get isNone => status == 'NONE';

  factory OrganizerRequestInfo.fromJson(Map<String, dynamic> json) {
    return OrganizerRequestInfo(
      status: json['status'] ?? 'NONE',
      organizationName: json['organizationName'],
      rejectReason: json['rejectReason'],
      role: json['role'],
    );
  }
}

/// Une demande vue par un modérateur.
class OrganizerRequestItem {
  final int id;
  final String userName;
  final String email;
  final String organizationName;
  final String phone;
  final String? link;
  final String description;
  final DateTime? submittedAt;

  const OrganizerRequestItem({
    required this.id,
    required this.userName,
    required this.email,
    required this.organizationName,
    required this.phone,
    this.link,
    required this.description,
    this.submittedAt,
  });

  factory OrganizerRequestItem.fromJson(Map<String, dynamic> json) {
    return OrganizerRequestItem(
      id: json['id'] ?? 0,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      organizationName: json['organizationName'] ?? '',
      phone: json['phone'] ?? '',
      link: json['link'],
      description: json['description'] ?? '',
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'])?.toLocal() : null,
    );
  }
}
