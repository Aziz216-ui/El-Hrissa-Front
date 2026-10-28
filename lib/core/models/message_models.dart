class MessageResponse {
  final int id;
  final int matchId;
  final int senderId;
  final String content;
  final DateTime? createdAt;

  MessageResponse({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.createdAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      id: json['id'] ?? 0,
      matchId: json['matchId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])?.toLocal()
          : null,
    );
  }
}
