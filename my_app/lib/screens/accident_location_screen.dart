import 'package:flutter/material.dart';

class AccidentLocationScreen extends StatelessWidget {
  final Map<String, dynamic>? notificationData;

  const AccidentLocationScreen({
    Key? key, 
    this.notificationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accident Location'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Accident Location Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (notificationData != null) ...[
                Text(
                  'Latitude: ${notificationData?['latitude'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Longitude: ${notificationData?['longitude'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ] else
                const Text(
                  'No additional location information available',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}