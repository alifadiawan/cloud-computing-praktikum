import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/base_url.dart';

class ApiService {
  // ========== GENERIC METHODS ==========

  /// Bangun URL GAS dengan query string manual.
  static Uri _buildUrl(String path, [Map<String, String>? extras]) {
    final buffer = StringBuffer('${AppConfig.baseUrl}?path=$path');
    extras?.forEach((k, v) => buffer.write('&$k=$v'));
    return Uri.parse(buffer.toString());
  }

  /// POST request dengan penanganan redirect manual Google Apps Script (302)
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    // Sisipkan path ke dalam body sebagai cadangan bagi GAS
    body["path"] = path; 
    
    final url = _buildUrl(path);
    
    print("----------------------------------------");
    print("[ApiService] SENDING POST TO: $url");
    print("[ApiService] PAYLOAD: ${jsonEncode(body)}");
    print("----------------------------------------");

    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'text/plain';
    request.body = jsonEncode(body);
    request.followRedirects = false; 

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("[ApiService] INITIAL STATUS: ${response.statusCode}");

      // Tangkap manual 302 Redirect dari Google Apps Script
      if (response.statusCode == 302 || response.statusCode == 303) {
        final location = response.headers['location'];
        if (location != null) {
          print("[ApiService] REDIRECTING TO: $location");
          // Perlu menggunakan GET untuk mengambil JSON dari URL redirect GAS
          response = await http.get(Uri.parse(location));
          print("[ApiService] REDIRECT STATUS: ${response.statusCode}");
        }
      }

      print("[ApiService] RESPONSE BODY: ${response.body}");
      print("----------------------------------------");

      try {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {"ok": true, "data": decoded};
      } catch (e) {
        print("[ApiService] PARSE ERROR: ${response.body}");
        return {"ok": false, "error": "Invalid JSON response"};
      }
    } catch (e) {
      print("[ApiService] FATAL ERROR: $e");
      return {"ok": false, "error": "Connection error: $e"};
    }
  }

  /// GET request
  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final url = _buildUrl(path, queryParams);
    print("[ApiService] GET: $url");

    try {
      final response = await http.get(url);
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {"ok": false, "error": "Invalid response format"};
      }
    } catch (e) {
      return {"ok": false, "error": "Connection error: $e"};
    }
  }

  // ========== PRESENCE ENDPOINTS ==========

  static Future<Map<String, dynamic>> checkIn({
    required String userId,
    required String deviceId,
    required String courseId,
    required String sessionId,
    required String qrToken,
  }) async {
    return post("presence/checkin", {
      "user_id": userId,
      "device_id": deviceId,
      "course_id": courseId,
      "session_id": sessionId,
      "qr_token": qrToken,
      "ts": DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>> generateQr({
    required String courseId,
    required String sessionId,
    String? dosenId,
    String? customToken,
  }) async {
    return post("presence/qr/generate", {
      "course_id": courseId,
      "session_id": sessionId,
      "dosen_id": dosenId,
      "custom_token": customToken,
      "ts": DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ========== TELEMETRY (GPS & ACCEL) ==========

  static Future<Map<String, dynamic>> postGps({
    String? userId,
    required String deviceId,
    required double lat,
    required double lng,
    double? accuracyM,
  }) async {
    return post("telemetry/gps", {
      "user_id": userId,
      "device_id": deviceId,
      "lat": lat,
      "lng": lng,
      "accuracy_m": accuracyM ?? 0.0,
      "ts": DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>> postAccel({
    required String deviceId,
    required List<Map<String, dynamic>> samples,
  }) async {
    return post("telemetry/accel", {
      "device_id": deviceId,
      "ts": DateTime.now().toUtc().toIso8601String(),
      "samples": samples,
    });
  }

  static Future<Map<String, dynamic>> getGpsLatest(String deviceId) async {
    return get("telemetry/gps/latest", queryParams: {"device_id": deviceId});
  }

  static Future<Map<String, dynamic>> getGpsHistory(String deviceId, {int limit = 50}) async {
    return get("telemetry/gps/history", queryParams: {"device_id": deviceId, "limit": limit.toString()});
  }

  static Future<Map<String, dynamic>> getAllGps() async {
    return get("telemetry/gps/all");
  }
}
