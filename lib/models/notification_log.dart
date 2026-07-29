class NotificationLog {
  final String id;
  final String cardId;
  final String cardName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final int daysRemaining;

  NotificationLog({
    required this.id,
    required this.cardId,
    required this.cardName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.daysRemaining,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'cardName': cardName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'daysRemaining': daysRemaining,
    };
  }

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      cardName: json['cardName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: (json['isRead'] as bool?) ?? false,
      daysRemaining: (json['daysRemaining'] as int?) ?? 0,
    );
  }

  NotificationLog copyWith({
    String? id,
    String? cardId,
    String? cardName,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    int? daysRemaining,
  }) {
    return NotificationLog(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      cardName: cardName ?? this.cardName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }
}
