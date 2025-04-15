import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/utils/session_manager.dart';

class ApiService {
  static const String BASE_URL = "https://11a2-154-176-149-63.ngrok-free.app/";

  // Generic GET request with authentication
  static Future<dynamic> get(String endpoint) async {
  String? token = await SessionManager.getAuthToken();
  print(token);
  
  if (token == null) {
    // Handle not authenticated case
    throw Exception("User not authenticated");
  }
  
  final response = await http.get(
    Uri.parse("$BASE_URL$endpoint"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );
  
  if (response.statusCode == 401) {
    // Token might be expired, try to refresh
    token = await SessionManager.refreshAuthToken();
    if (token != null) {
      // Retry with new token
      return await get(endpoint);
    } else {
      throw Exception("Session expired");
    }
  }
  
  if (response.statusCode >= 200 && response.statusCode < 300) {
    print(response.body);
    // Return the decoded JSON - this could be a Map or a List
    return jsonDecode(response.body);
  } else {
    throw Exception("API Error: ${response.statusCode} - ${response.body}");
  }
}

  // Generic POST request with authentication
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    String? token = await SessionManager.getAuthToken();

    if (token == null) {
      // Handle not authenticated case
      throw Exception("User not authenticated");
    }

    final response = await http.post(
      Uri.parse("$BASE_URL$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 401) {
      // Token might be expired, try to refresh
      token = await SessionManager.refreshAuthToken();

      if (token != null) {
        // Retry with new token
        return await post(endpoint, data);
      } else {
        throw Exception("Session expired");
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception("API Error: ${response.statusCode} - ${response.body}");
    }
  }

  static put(String endpoint, Map<String, dynamic> data) 
    async {
    String? token = await SessionManager.getAuthToken();

    if (token == null) {
      // Handle not authenticated case
      throw Exception("User not authenticated");
    }

    final response = await http.put(
      Uri.parse("$BASE_URL$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 401) {
      // Token might be expired, try to refresh
      token = await SessionManager.refreshAuthToken();

      if (token != null) {
        // Retry with new token
        return await put(endpoint, data);
      } else {
        throw Exception("Session expired");
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception("API Error: ${response.statusCode} - ${response.body}");
    }
  }

  
}
