import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_app/front_end_helper/curved_clipper.dart';
import 'package:my_app/services/fcm_service.dart';
import 'package:my_app/Model/notification_model.dart';
import 'package:my_app/Repository/notification_repository.dart';
import 'package:intl/intl.dart';
import 'package:my_app/services/notification_handler_service.dart';
import 'package:my_app/widgets/navigation_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repository = NotificationRepository();
  final NotificationHandler _notificationHandler = NotificationHandler();
  List _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future _loadNotifications() async {
    final notifications = await _repository.getAllNotifications();
    setState(() {
      _notifications = notifications;
    });
  }

  Future _clearAllNotifications() async {
    await _repository.clearAllNotifications();
    _loadNotifications();
  }

  Future<void> simulateNotification() async {
    // Create a sample notification with coordinates
    final sampleNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Test Notification',
      body: 'This is a test notification with location data.',
      timestamp: DateTime.now(),
      latitude: 37.4220, // Example coordinates (Google HQ)
      longitude: -122.0841,
    );

    // Save to repository
    await _repository.saveNotification(sampleNotification);

    // Show as local notification
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationHandler.flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      sampleNotification.title,
      sampleNotification.body,
      notificationDetails,
      payload:
          '{"latitude": "${sampleNotification.latitude}", "longitude": "${sampleNotification.longitude}"}',
    );

    // Refresh the list
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications', style: TextStyle(color: Colors.white))
      ,backgroundColor:Color(0xFFBE0000) ,
      iconTheme: IconThemeData(color: Colors.white),),
      
      drawer: CustomNavigationDrawer(currentRoute: '/notification'),
      
      body: Stack(
        children: [
          
           // Red curved bar at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: CurvedBottomClipper(),
              child: Container(
                height: 20,
                color: Color(0xFFBE0000),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 30.0),
                ),
              ),
            ),
          ),
          
          _notifications.isEmpty
              ? const Center(
                child: Text(
                  'No notifications yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              
              :ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return ListTile(
                    contentPadding: EdgeInsets.all(20),
                    title: Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy - HH:mm',
                          ).format(notification.timestamp),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (notification.latitude != null &&
                          notification.longitude != null) {
                        _notificationHandler.openLocationInMaps(
                          notification.latitude!,
                          notification.longitude!,
                        );
                      } else {
                        print('Notification tapped: ${notification.title}');
                      }
                    },
                  );
                },
              ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _clearAllNotifications,
              backgroundColor: Colors.red,
              child: Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: 'Clear All Notifications',
            ),
          ),
          Positioned(
            right: 16,
            bottom: 80, // Position above the delete button
            child: FloatingActionButton(
              onPressed: simulateNotification,
              backgroundColor: Colors.blue,
              child: Icon(Icons.notifications_active, color: Colors.white),
              tooltip: 'Simulate Notification',
            ),
          ),
        ],
      ),
    );
  }
}
