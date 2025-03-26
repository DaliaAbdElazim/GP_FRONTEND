import 'package:flutter/material.dart';
import 'package:my_app/services/fcm_service.dart';
import 'package:my_app/Model/notification_model.dart';
import 'package:my_app/Repository/notification_repository.dart';
import 'package:intl/intl.dart';
import 'package:my_app/services/notification_handler_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/base_screen.dart';

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



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BaseScreen(
          title: 'Notifications',
          currentRoute: '/notification',
          body: _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
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
                            DateFormat('MMM dd, yyyy - HH:mm')
                                .format(notification.timestamp),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                       // print("longitude "+notification.longitude+" "+notification.latitude);
                        if (notification.latitude != null && notification.longitude != null) {
                          _notificationHandler.openLocationInMaps(notification.latitude!, notification.longitude!);
                        } else {
                          print('Notification tapped: ${notification.title}');
                        }
                      },
                    );
                  },
                ),
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
      ],
    );
  }
}
