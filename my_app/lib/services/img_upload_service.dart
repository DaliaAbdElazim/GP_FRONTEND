import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

// Data Transfer Objects (DTOs)
class CreateUploadsDto {
  final String userId;
  final LocationDto location;
  final List<String> imageUrls; // Store Firebase URLs
  final bool isGuestUpload;

  CreateUploadsDto({
    required this.userId,
    required this.location,
    required this.imageUrls,
    this.isGuestUpload = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'location': location.toJson(),
      'imageUrls': imageUrls,
      'isGuestUpload': isGuestUpload,
    };
  }
}

class LocationDto {
  final double longitude;
  final double latitude;
  final bool isValid;

  LocationDto({
    required this.longitude,
    required this.latitude,
    this.isValid = true,
  });

  // Factory constructor to handle invalid values
  factory LocationDto.safe({double? longitude, double? latitude}) {
    // Check if values are valid numbers (not NaN or null)
    bool isLongitudeValid = longitude != null && !longitude.isNaN && longitude.isFinite;
    bool isLatitudeValid = latitude != null && !latitude.isNaN && latitude.isFinite;
    
    return LocationDto(
      longitude: isLongitudeValid ? longitude! : 0.0,
      latitude: isLatitudeValid ? latitude! : 0.0,
      isValid: isLongitudeValid && isLatitudeValid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}

class UploadResponse {
  final bool success;
  final String message;
  final List<String>? uploadedIds;
  final List<String>? imageUrls;

  UploadResponse({
    required this.success,
    required this.message,
    this.uploadedIds,
    this.imageUrls,
  });
  
  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown response',
      uploadedIds: json['data'] != null 
        ? List<String>.from(json['data']['uploadedIds'] ?? [])
        : null,
      imageUrls: json['data'] != null 
        ? List<String>.from(json['data']['imageUrls'] ?? [])
        : null,
    );
  }
}

class UploadsService {
  // Update this to your real backend URL
  static const String baseUrl = 'https://ec0e-154-176-127-20.ngrok-free.app';
  static const int maxRetries = 2;
  
  // Use your specific Firebase Storage bucket
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://acitrack.firebasestorage.app'
  );
  
  final Uuid _uuid = Uuid();

  // Method to get current location with improved error handling
  Future<LocationDto> getCurrentLocation() async {
    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied');
        return LocationDto.safe();
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('Location permission denied forever');
      return LocationDto.safe();
    }

    try {
      // Get the current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      );
      
      // Explicitly check for valid values
      double lat = position.latitude;
      double lng = position.longitude;
      
      print('Raw location values - Latitude: $lat, Longitude: $lng');
      
      if (lat.isNaN || lng.isNaN || !lat.isFinite || !lng.isFinite) {
        print('Invalid location values detected, using safe defaults');
        return LocationDto.safe();
      }
      
      return LocationDto(
        longitude: lng,
        latitude: lat,
      );
    } catch (e) {
      print('Error getting location: ${e.toString()}');
      return LocationDto.safe();
    }
  }

  // Upload a single image to Firebase Storage
  Future<String?> _uploadToFirebaseStorage(File imageFile, String userId) async {
    try {
      // Generate a unique filename to avoid collisions
      String fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
      
      // Reference to the storage location
      Reference storageRef = _storage.ref().child('user_uploads/$userId/$fileName');
      
      // Upload the file with metadata
      UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/${path.extension(imageFile.path).substring(1)}', // jpg -> image/jpg
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Wait for the upload to complete
      await uploadTask;
      
      // Get the download URL
      String downloadUrl = await storageRef.getDownloadURL();
      print('File uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading file to Firebase Storage: ${e.toString()}');
      return null;
    }
  }

  // Main upload method - now uploads to Firebase first, then sends URLs to backend
  Future<UploadResponse> uploadImages({
    required String userId,
    required List<File> imageFiles,
    required LocationDto location,
    bool isGuestUpload = false,
  }) async {
    int retryCount = 0;
    List<String> uploadedUrls = [];
    
    // First, upload all images to Firebase Storage
    for (var imageFile in imageFiles) {
      String? downloadUrl = await _uploadToFirebaseStorage(imageFile, userId);
      if (downloadUrl != null) {
        uploadedUrls.add(downloadUrl);
      } else {
        // If any upload fails, return an error
        return UploadResponse(
          success: false,
          message: 'Failed to upload one or more images to Firebase Storage',
        );
      }
    }
    
    // If we couldn't upload any images, return error
    if (uploadedUrls.isEmpty && imageFiles.isNotEmpty) {
      return UploadResponse(
        success: false,
        message: 'Failed to upload any images to Firebase Storage',
      );
    }
    
    // Now send the metadata and URLs to the backend
    while (retryCount <= maxRetries) {
      try {
        // Use safe values for coordinates
        double safeLat = location.latitude.isNaN ? 0.0 : location.latitude;
        double safeLng = location.longitude.isNaN ? 0.0 : location.longitude;
        
        print('Using location values - Latitude: $safeLat, Longitude: $safeLng');

        // Prepare the request body
        final requestBody = {
          'userId': userId,
          'location': {
            'longitude': safeLng,
            'latitude': safeLat,
          },
          'imageUrls': uploadedUrls,
          'isGuestUpload': isGuestUpload,
        };

        print('Sending request to backend with data: ${json.encode(requestBody)}');
        
        // Send JSON request to backend
        final response = await http.post(
          Uri.parse('$baseUrl/uploads'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(requestBody),
        ).timeout(
          Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );
        
        print('Response status: ${response.statusCode}');
        print('Response body preview: ${response.body.length > 100 ? response.body.substring(0, 100) + "..." : response.body}');
        
        // Check if response is HTML (common error case)
        if (response.body.trim().startsWith('<html') || 
            response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.contains('<head>')) {
          
          print('Received HTML response instead of expected JSON');
          
          if (retryCount < maxRetries) {
            retryCount++;
            print('Retrying upload (attempt ${retryCount} of $maxRetries)...');
            await Future.delayed(Duration(seconds: 2 * retryCount)); // Exponential backoff
            continue; // Retry
          } else {
            return UploadResponse(
              success: false,
              message: 'Server returned HTML instead of JSON. API endpoint may be unreachable.',
              imageUrls: uploadedUrls, // Return URLs even if backend failed
            );
          }
        }
        
        try {
          // Parse the response JSON
          var jsonResponse = json.decode(response.body);
          print('--------------------------------');
          print(response.statusCode);
          if (response.statusCode == 201 || response.statusCode == 200) {
            return UploadResponse(
              success: true,
              message: 'Upload successful',
              uploadedIds: jsonResponse['data']?['uploadedIds'] != null 
                ? List<String>.from(jsonResponse['data']['uploadedIds'])
                : [],
              imageUrls: uploadedUrls,
            );
          } else {
            return UploadResponse(
              success: false,
              message: jsonResponse['message'] ?? 'Upload failed with status ${response.statusCode}',
              imageUrls: uploadedUrls, // Return URLs even if backend failed
            );
          }
        } catch (parseError) {
          print("Error parsing response: $parseError");
          
          if (retryCount < maxRetries) {
            retryCount++;
            print('Retrying upload after parse error (attempt ${retryCount} of $maxRetries)...');
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue; // Retry
          }
          
          return UploadResponse(
            success: false,
            message: 'Failed to parse server response. Received invalid data.',
            imageUrls: uploadedUrls, // Return URLs even if backend failed
          );
        }
      } catch (e) {
        print('Upload error: ${e.toString()}');
        
        if (e is TimeoutException || retryCount >= maxRetries) {
          return UploadResponse(
            success: false,
            message: 'Network error: ${e.toString()}',
            imageUrls: uploadedUrls, // Return URLs even if backend failed
          );
        }
        
        retryCount++;
        print('Retrying upload after error (attempt ${retryCount} of $maxRetries)...');
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
    
    // This should only be reached if all retries failed
    return UploadResponse(
      success: false,
      message: 'Upload failed after multiple attempts',
      imageUrls: uploadedUrls, // Return URLs even if backend failed
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}