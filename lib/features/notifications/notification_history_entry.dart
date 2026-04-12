import 'dart:convert';

class NotificationHistoryEntry {
  const NotificationHistoryEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.createdAt,
  });

  factory NotificationHistoryEntry.fromMap(Map<String, dynamic> map) {
    return NotificationHistoryEntry(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      actionLabel: map['actionLabel'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory NotificationHistoryEntry.fromJson(String source) {
    return NotificationHistoryEntry.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  final String id;
  final String title;
  final String description;
  final String actionLabel;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'actionLabel': actionLabel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());
}
