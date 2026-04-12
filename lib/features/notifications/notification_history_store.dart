import 'package:opration/core/services/cache_helper/cache_values.dart';
import 'package:opration/features/notifications/notification_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistoryStore {
  NotificationHistoryStore({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  List<NotificationHistoryEntry> loadHistory() {
    final savedItems =
        sharedPreferences.getStringList(CacheKeys.notificationsHistory) ?? [];
    final items = savedItems
        .map(NotificationHistoryEntry.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> addEntry(NotificationHistoryEntry entry) async {
    final entries = loadHistory();
    entries.removeWhere((item) => item.id == entry.id);
    entries.insert(0, entry);

    await sharedPreferences.setStringList(
      CacheKeys.notificationsHistory,
      entries.take(50).map((item) => item.toJson()).toList(),
    );
  }
}
