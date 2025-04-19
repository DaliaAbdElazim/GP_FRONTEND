import 'package:flutter/material.dart';
import 'package:my_app/front_end_helper/curved_clipper.dart';
import 'package:my_app/widgets/navigation_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/session_manager.dart';
import '../services/api_service.dart';

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
      // COMMENTED OUT: API retrieval logic
      /*
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
      */
      
      // Create 3 dummy contributions
      List<Map<String, dynamic>> dummyUploads = [
        {
          'id': 'dummy1',
          'isGuestUpload': false,
          'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'location': {'latitude': 40.7128, 'longitude': -74.0060},
          'geohash': 'dr5r7p',
          'accidentId': 'acc123',
          'photoURLs': [
            'https://example.com/photo1.jpg',
            'https://example.com/photo2.jpg'
          ],
        },
        {
          'id': 'dummy2',
          'isGuestUpload': true,
          'createdAt': DateTime.now().subtract(Duration(days: 2)).millisecondsSinceEpoch ~/ 1000,
          'location': {'latitude': 34.0522, 'longitude': -118.2437},
          'geohash': 'dr5r8q',
          'accidentId': null,
          'photoURLs': [
            'https://www.google.com/imgres?q=car%20photo&imgurl=https%3A%2F%2Fmedia.architecturaldigest.com%2Fphotos%2F66a914f1a958d12e0cc94a8e%2F16%3A9%2Fw_2992%2Ch_1683%2Cc_limit%2FDSC_5903.jpg&imgrefurl=https%3A%2F%2Fwww.architecturaldigest.com%2Fstory%2Fi-test-drove-lamborghinis-dollar600000-car-heres-what-i-thought-of-their-most-powerful-car-ever&docid=nh70ZPd76z93PM&tbnid=_9GEqijjJSZ3vM&vet=12ahUKEwilmcqF8eGMAxVxKvsDHUisPeIQM3oECBwQAA..i&w=2992&h=1683&hcb=2&ved=2ahUKEwilmcqF8eGMAxVxKvsDHUisPeIQM3oECBwQAA'
          ],
        },
        {
          'id': 'dummy3',
          'isGuestUpload': false,
          'createdAt': DateTime.now().subtract(Duration(days: 5)).millisecondsSinceEpoch ~/ 1000,
          'location': {'latitude': 51.5074, 'longitude': -0.1278},
          'geohash': '9h3er7',
          'accidentId': 'acc456',
          'photoURLs': [
            'https://example.com/photo4.jpg',
            'https://example.com/photo5.jpg',
            'https://example.com/photo6.jpg'
          ],
        },
      ];
      
      // Map the dummy data to a format suitable for the UI
      setState(() {
        _contributions = dummyUploads.map<Map<String, dynamic>>((upload) {
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
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final Color redBorder = Color(0xFFBE0000);
        final Color black = const Color.fromARGB(255, 7, 7, 7);
        
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: redBorder, width: 2),
              left: BorderSide(color: redBorder, width: 2),
              right: BorderSide(color: redBorder, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    contribution['type'] ?? 'Unknown Type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: redBorder),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: redBorder.withOpacity(0.5), thickness: 1),
              SizedBox(height: 10),
              Text('Date: ${contribution['date'] ?? 'Unknown'}', style: TextStyle(color: black)),
              Text('Location: ${contribution['location'] ?? 'Unknown'}', style: TextStyle(color: black)),
              Text('Geohash: ${contribution['geohash'] ?? 'Unknown'}', style: TextStyle(color: black)),
              Text('Status: ${contribution['status'] ?? 'Unknown'}', style: TextStyle(color: black)),
              SizedBox(height: 20),
              Text(
                'Attached Images:',
                style: TextStyle(fontWeight: FontWeight.bold, color: black),
              ),
              SizedBox(height: 10),
              Container(
                height: 120,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ((contribution['images'] ?? []) as List).map<Widget>((imageUrl) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: redBorder, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(redBorder),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Icon(Icons.error, color: redBorder),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: redBorder,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define the colors to be used throughout
    final Color black = const Color.fromARGB(255, 7, 7, 7);
    final Color redBorder = Color(0xFFBE0000);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFBE0000),
        title: Text('My Contributions', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: CustomNavigationDrawer(currentRoute: '/contributions'),
      body: Stack(
        children: [
          // Top red bar that sits behind everything
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
          
          // Main content
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(redBorder),
                  ),
                )
              : _contributions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 64,
                            color: redBorder,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No contributions yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your uploaded content will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _contributions.length,
                        itemBuilder: (context, index) {
                          final contribution = _contributions[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: redBorder, width: 1.5),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Icon(
                                    contribution['type'] == 'Guest Upload'
                                        ? Icons.person_outline
                                        : Icons.verified_user,
                                    color: redBorder,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    contribution['type'] ?? 'Unknown Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: black,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Divider(color: redBorder.withOpacity(0.5), thickness: 1),
                                  SizedBox(height: 8),
                                  Text('Date: ${contribution['date'] ?? 'Unknown'}', style: TextStyle(color: black)),
                                  Text('Location: ${contribution['location'] ?? 'Unknown'}', style: TextStyle(color: black)),
                                  Text('Status: ${contribution['status'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        color: contribution['status'] == 'Linked to Accident'
                                            ? redBorder
                                            : black,
                                        fontWeight: contribution['status'] == 'Linked to Accident'
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      )),
                                  if ((contribution['images'] ?? []).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.photo_library, size: 14, color: black.withOpacity(0.7)),
                                          SizedBox(width: 4),
                                          Text(
                                            '${(contribution['images'] as List).length} image(s)',
                                            style: TextStyle(
                                              color: black.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: redBorder),
                              onTap: () => _viewContributionDetails(contribution),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}