class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;
  final double ? latitude;
  final double ? longitude;
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.additionalData,  this.latitude, this.longitude,
  });

  // Convert from JSON (useful for storing/retrieving)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
  return NotificationModel(
    id: json['id'] ?? DateTime.now().toIso8601String(),
    title: json['title'] ?? 'Notification',
    body: json['body'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    additionalData: json['additionalData'],
    latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
    longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
  );
}

  // Convert to JSON
  Map<String, dynamic> toJson() {
    print("-----------------------------");
    print("toJson()");
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
      'longitude':longitude,
      'latitude':latitude,
    };
  }
}