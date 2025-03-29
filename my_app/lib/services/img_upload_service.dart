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

  LocationDto({
    required this.longitude,
    required this.latitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}


class UploadsService {
  static const String baseUrl = 'https://b01e-154-176-181-242.ngrok-free.app';

  Future<bool> uploadImages({
    required String userId,
    required List<File> imageFiles,
    required LocationDto location,
    bool isGuestUpload = false,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/uploads')
      );

      // Modify DTO serialization
      request.fields['data'] = jsonEncode({
        'userId': userId,
        'longitude': location.longitude,
        'latitude': location.latitude,
        'isGuestUpload': isGuestUpload
      });

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

      // Send the request
      print(request.fields);
      var response = await request.send();

      var responseBody = await response.stream.bytesToString();
      
      try {
        var jsonResponse = json.decode(responseBody);
        
        if (response.statusCode == 201) {
          return true;
        } else {
          print('------------------------------------');
          return false;
        }
      } catch (parseError) {
        print("#################################");
        return false;
      }
    } catch (e) {
      print('Upload error: ${e.toString()}');
      return false;
    }
  }

  // Method to get current location (you might want to use a location service)
  Future<LocationDto> getCurrentLocation() async {
     // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, return default location
          return LocationDto(longitude: 0.0, latitude: 0.0);
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied, handle this case
        // You might want to show a dialog instructing the user to enable location in settings
        return LocationDto(longitude: 0.0, latitude: 0.0);
      }

      try {
        // Get the current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        return LocationDto(
          longitude: position.longitude,
          latitude: position.latitude,
        );
      } catch (e) {
        print('Error getting location: ${e.toString()}');
        // Return default location on error
        return LocationDto(longitude: 0.0, latitude: 0.0);
      }
  }
}