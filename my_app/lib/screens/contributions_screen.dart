import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/base_screen.dart';
import '../utils/session_manager.dart';
import '../utils/api_service.dart';

class ContributionsScreen extends StatefulWidget {
  @override
  _ContributionsScreenState createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _contributions = [];

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(SessionManager.KEY_USER_ID);
      
      if (userId == null || userId.isEmpty) {
        throw Exception("User ID not found");
      }

      // Get the response from the API
      final response = await ApiService.get('user/$userId/uploads');
      
      // Initialize an empty list for the uploads
      List<dynamic> uploads = [];
      
      // Handle the response based on its type
      if (response is List) {
        // If the response is already a list, use it directly
        uploads = response;
      } else if (response is Map<String, dynamic>) {
        // If the response is a Map, try to extract the list from common key names
        if (response.containsKey('uploads')) {
          final data = response['uploads'];
          uploads = data is List ? data : [data];
        } else if (response.containsKey('data')) {
          final data = response['data'];
          uploads = data is List ? data : [data];
        } else {
          // If no specific key, treat the entire response as a single item
          uploads = [response];
        }
      } else {
        throw Exception("Unexpected API response format: ${response.runtimeType}");
      }
      
      // Map the API response to a format suitable for the UI
      setState(() {
        _contributions = uploads.map<Map<String, dynamic>>((upload) {
          if (upload is! Map<String, dynamic>) {
            print("Warning: Invalid upload format: $upload");
            return {'type': 'Invalid Data'};
          }
          
          return {
            'id': upload['id'] ?? '',
            'type': upload['isGuestUpload'] == true ? 'Guest Upload' : 'Contribution',
            'date': _formatDate(upload['createdAt']),
            'location': _formatLocation(upload['location']),
            'geohash': upload['geohash'] ?? '',
            'status': upload['accidentId'] != null ? 'Linked to Accident' : 'Unlinked',
            'images': upload['photoURLs'] ?? [],
            'rawData': upload, // Keep full upload data for detailed view
          };
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading contributions: $e");
      _showMessage('Failed to load contributions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to format date
  String _formatDate(dynamic createdAt) {
    try {
      if (createdAt == null) return 'Unknown Date';

      // Handle different timestamp formats
      if (createdAt is Map<String, dynamic> && createdAt.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt['_seconds'] * 1000)
            .toString()
            .split(' ')[0];
      }
      
      if (createdAt is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt * 1000)
            .toString()
            .split(' ')[0];
      }
      
      return createdAt.toString().split(' ')[0];
    } catch (e) {
      print("Error formatting date: $e");
      return 'Invalid Date';
    }
  }

  // Helper method to format location
  String _formatLocation(dynamic location) {
    try {
      if (location is Map<String, dynamic>) {
        return '${location['latitude'] ?? 'N/A'}, ${location['longitude'] ?? 'N/A'}';
      }
      return 'Location Not Available';
    } catch (e) {
      print("Error formatting location: $e");
      return 'Location Not Available';
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _viewContributionDetails(Map<String, dynamic> contribution) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contribution['type'] ?? 'Unknown Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text('Date: ${contribution['date'] ?? 'Unknown'}'),
              Text('Location: ${contribution['location'] ?? 'Unknown'}'),
              Text('Geohash: ${contribution['geohash'] ?? 'Unknown'}'),
              Text('Status: ${contribution['status'] ?? 'Unknown'}'),
              SizedBox(height: 20),
              Text(
                'Attached Images:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ((contribution['images'] ?? []) as List).map<Widget>((imageUrl) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Image.network(
                         imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'My Contributions',
      currentRoute: '/contributions',
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _contributions.isEmpty
              ? Center(
                  child: Text(
                    'No contributions yet',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _contributions.length,
                  itemBuilder: (context, index) {
                    final contribution = _contributions[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          contribution['type'] ?? 'Unknown Type',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${contribution['date'] ?? 'Unknown'}'),
                            Text('Location: ${contribution['location'] ?? 'Unknown'}'),
                            Text('Status: ${contribution['status'] ?? 'Unknown'}'),
                          ],
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () => _viewContributionDetails(contribution),
                      ),
                    );
                  },
                ),
    );
  }
}