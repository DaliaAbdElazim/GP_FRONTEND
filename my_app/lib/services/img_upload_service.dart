import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

// Data Transfer Objects (DTOs)
class CreateUploadsDto {
  final String userId;
  final LocationDto location;
  final bool isGuestUpload;

  CreateUploadsDto({
    required this.userId,
    required this.location,
    this.isGuestUpload = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'location': location.toJson(),
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

  UploadResponse({
    required this.success,
    required this.message,
    this.uploadedIds,
  });
  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown response',
      uploadedIds: json['data'] != null 
        ? List<String>.from(json['data']['uploadedIds'] ?? [])
        : null,
    );
  }
}

class UploadsService {
  // Update this to your real backend URL
  static const String baseUrl = 'https://76c1-196-137-48-30.ngrok-free.app';
  static const int maxRetries = 2;

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

  Future<UploadResponse> uploadImages({
    required String userId,
    required List<File> imageFiles,
    required LocationDto location,
    bool isGuestUpload = false,
  }) async {
    int retryCount = 0;
    
    while (retryCount <= maxRetries) {
      try {
        var request = http.MultipartRequest(
          'POST', 
          Uri.parse('$baseUrl/uploads')
        );

        // Use safe values for coordinates
        double safeLat = location.latitude.isNaN ? 0.0 : location.latitude;
        double safeLng = location.longitude.isNaN ? 0.0 : location.longitude;
        
        print('Using location values - Latitude: $safeLat, Longitude: $safeLng');

        // Add data fields directly (not as nested JSON)
        request.fields['userId'] = userId;
        request.fields['longitude'] = safeLng.toString();
        request.fields['latitude'] = safeLat.toString();
        request.fields['isGuestUpload'] = isGuestUpload.toString();

        // Add image files
        for (var imageFile in imageFiles) {
          final mimeType = lookupMimeType(imageFile.path);
          request.files.add(
            await http.MultipartFile.fromPath(
              'files', 
              imageFile.path,
              filename: path.basename(imageFile.path),
              contentType: MediaType.parse(mimeType ?? 'application/octet-stream')
            )
          );
        }

        // Add headers
        request.headers['Accept'] = 'application/json';

        // Log request details for debugging
        print('Sending upload request to: ${request.url}');
        print('Fields: ${request.fields}');
        print('Files count: ${request.files.length}');

        // Send the request with timeout
        var responseStream = await request.send().timeout(
          Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );
        
        // Get response body
        var responseBody = await responseStream.stream.bytesToString();
        print('Response status: ${responseStream.statusCode}');
        print('Response body preview: ${responseBody.length > 100 ? responseBody.substring(0, 100) + "..." : responseBody}');
        
        // Check if response is HTML (common error case)
        if (responseBody.trim().startsWith('<html') || 
            responseBody.trim().startsWith('<!DOCTYPE') ||
            responseBody.contains('<head>')) {
          
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
            );
          }
        }
        
        try {
          // Parse the response JSON
          var jsonResponse = json.decode(responseBody);
          
          if (responseStream.statusCode == 201 || responseStream.statusCode == 200) {
            return UploadResponse(
              success: true,
              message: 'Upload successful',
              uploadedIds: jsonResponse['data']?['uploadedIds'] != null 
                ? List<String>.from(jsonResponse['data']['uploadedIds'])
                : [],
            );
          } else {
            return UploadResponse(
              success: false,
              message: jsonResponse['message'] ?? 'Upload failed with status ${responseStream.statusCode}',
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
          );
        }
      } catch (e) {
        print('Upload error: ${e.toString()}');
        
        if (e is TimeoutException || retryCount >= maxRetries) {
          return UploadResponse(
            success: false,
            message: 'Network error: ${e.toString()}',
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
    );
  }
}
  class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}

  
