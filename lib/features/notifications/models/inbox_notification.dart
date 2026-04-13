class InboxNotification {
  final String id;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;

  InboxNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  InboxNotification copyWith({
    String? id,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return InboxNotification(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    return InboxNotification(
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
