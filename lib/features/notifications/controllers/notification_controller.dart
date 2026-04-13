import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarri_ride/features/notifications/models/inbox_notification.dart';

const String _kInboxStorageKey = 'notification_inbox_items_v1';
const int _kMaxInboxItems = 50;

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  final RxInt unreadCount = 0.obs;
  final RxList<InboxNotification> items = <InboxNotification>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInboxFromStorage();
  }

  Future<void> _loadInboxFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kInboxStorageKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = list
          .map((e) => InboxNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      items.assignAll(loaded);
    } catch (e) {
      print('NotificationController: Failed to load inbox: $e');
    }
  }

  Future<void> _persistInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_kInboxStorageKey, encoded);
    } catch (e) {
      print('NotificationController: Failed to persist inbox: $e');
    }
  }

  void _trimInbox() {
    if (items.length <= _kMaxInboxItems) return;
    items.removeRange(_kMaxInboxItems, items.length);
  }

  /// Parses WebSocket `notification:new` (and similar) payloads defensively.
  InboxNotification? _tryParseInboxEntry(Map<dynamic, dynamic> data) {
    Map<dynamic, dynamic>? n;
    final nested = data['notification'];
    if (nested is Map) {
      n = nested;
    }

    String? msg = _stringFrom(data['message']) ??
        _stringFrom(data['body']) ??
        (n != null ? _stringFrom(n['message']) : null) ??
        (n != null ? _stringFrom(n['body']) : null);

    final title = _stringFrom(data['title']) ??
        (n != null ? _stringFrom(n['title']) : null);

    if ((msg == null || msg.isEmpty) && title != null && title.isNotEmpty) {
      msg = title;
    } else if (title != null &&
        title.isNotEmpty &&
        msg != null &&
        msg.isNotEmpty &&
        title != msg) {
      msg = '$title: $msg';
    }

    if (msg == null || msg.trim().isEmpty) return null;

    final type = _stringFrom(data['type']) ??
        (n != null ? _stringFrom(n['type']) : null) ??
        'system';

    DateTime ts = DateTime.now();
    final created = data['createdAt'] ?? data['timestamp'] ?? n?['createdAt'];
    if (created is String) {
      ts = DateTime.tryParse(created) ?? ts;
    } else if (created is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(created);
    }

    final id = _stringFrom(data['id']) ??
        _stringFrom(n?['id']) ??
        'ws_${ts.millisecondsSinceEpoch}';

    return InboxNotification(
      id: id,
      message: msg.trim(),
      type: type,
      timestamp: ts,
      isRead: false,
    );
  }

  String? _stringFrom(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  void handleNewNotification(dynamic notificationData) {
    print(
      "NotificationController: Handling new notification data: $notificationData",
    );

    if (notificationData is Map) {
      final map = Map<dynamic, dynamic>.from(notificationData);

      if (map['unreadCount'] is int) {
        unreadCount.value = map['unreadCount'] as int;
        print(
          "NotificationController: Unread count updated to ${unreadCount.value}",
        );
      }

      final entry = _tryParseInboxEntry(map);
      if (entry != null) {
        items.removeWhere((e) => e.id == entry.id);
        items.insert(0, entry);
        _trimInbox();
        _persistInbox();
        if (!entry.isRead && map['unreadCount'] is! int) {
          unreadCount.value++;
        }
      }
    } else {
      print(
        "NotificationController: Received invalid data format for notification:new",
      );
    }
  }

  /// Foreground FCM — adds a row when title/body exist. Returns whether a row was added.
  bool appendFromRemoteMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title?.trim();
    final body = n?.body?.trim();
    String? text;
    if (title != null && title.isNotEmpty && body != null && body.isNotEmpty) {
      text = '$title: $body';
    } else {
      text = (body != null && body.isNotEmpty)
          ? body
          : (title != null && title.isNotEmpty)
              ? title
              : null;
    }
    if (text == null || text.isEmpty) return false;

    final type = message.data['type']?.toString() ?? 'system';
    final id =
        'fcm_${DateTime.now().millisecondsSinceEpoch}_${message.messageId ?? ''}';

    items.insert(
      0,
      InboxNotification(
        id: id,
        message: text,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
    _trimInbox();
    _persistInbox();
    return true;
  }

  void markAsRead() {
    for (var i = 0; i < items.length; i++) {
      if (!items[i].isRead) {
        items[i] = items[i].copyWith(isRead: true);
      }
    }
    unreadCount.value = 0;
    items.refresh();
    _persistInbox();
    print("NotificationController: Marked notifications as read.");
  }

  void clearAll() {
    items.clear();
    unreadCount.value = 0;
    _persistInbox();
  }

  void markSingleRead(String id) {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    if (items[i].isRead) return;
    items[i] = items[i].copyWith(isRead: true);
    items.refresh();
    if (unreadCount.value > 0) {
      unreadCount.value--;
    }
    _persistInbox();
  }
}
