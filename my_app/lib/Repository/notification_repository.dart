import 'package:my_app/Model/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class NotificationRepository {
  static const String _storageKey = 'app_notifications_v1';

  // Save a new notification
  Future<void> saveNotification(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Retrieve existing notifications
    List<NotificationModel> notifications = await getAllNotifications();
    
    // Add new notification to the list
    notifications.insert(0, notification); // Add to the beginning
    
    // Limit to last 50 notifications to prevent storage overflow
    if (notifications.length > 50) {
      notifications = notifications.sublist(0, 50);
    }

    // Convert to JSON list
    final jsonList = notifications.map((n) => n.toJson()).toList();
    
    // Save to SharedPreferences
    await prefs.setStringList(
      _storageKey, 
      jsonList.map((n) => json.encode(n)).toList()
    );
  }

  // Get all notifications
  Future<List<NotificationModel>> getAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Retrieve notification list
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    
    // Convert back to NotificationModel objects
    return jsonList
      .map((jsonString) => 
        NotificationModel.fromJson(json.decode(jsonString))
      )
      .toList();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}