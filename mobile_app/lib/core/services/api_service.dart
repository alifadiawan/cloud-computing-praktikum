import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/base_url.dart';

class ApiService {
  // ========== GENERIC METHODS ==========

  /// Bangun URL GAS dengan query string manual.
  /// PENTING: Tidak pakai Uri.replace(queryParameters:) karena Dart akan
  /// encode '/' menjadi '%2F', sehingga e.parameter.path di GAS tidak cocok.
  static Uri _buildUrl(String path, [Map<String, String>? extras]) {
    final buffer = StringBuffer('${AppConfig.baseUrl}?path=$path');
    extras?.forEach((k, v) => buffer.write('&$k=$v'));
    return Uri.parse(buffer.toString());
  }

  /// POST request using text/plain to avoid CORS preflight on web
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = _buildUrl(path);

    try {
      // Use text/plain to avoid CORS preflight (OPTIONS) request
      // GAS still parses the body via JSON.parse(e.postData.contents)
      final response = await http.post(
        url,
        headers: {"Content-Type": "text/plain"},
        body: jsonEncode(body),
      );

      // Coba parse respons JSON dari GAS
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print("Gagal parse respons dari GAS (POST): ${response.body}");
        return {"ok": false, "error": "invalid_response"};
      }
    } catch (e) {
      print("Error koneksi POST: $e");
      return {"ok": false, "error": "network_error"};
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse("${AppConfig.baseUrl}?path=$path");

    try {
      final response = await http.get(url);
      
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print("Gagal parse respons dari GAS (GET): ${response.body}");
        return {"ok": false, "error": "invalid_response"};
      }
    } catch (e) {
      print("Error koneksi GET: $e");
      return {"ok": false, "error": "network_error"};
    }
  }

  // ========== PRESENCE ENDPOINTS (MODUL 1) ==========

  /// Check-in via QR (Mahasiswa)
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

  /// Generate QR Code (Dosen)
  static Future<Map<String, dynamic>> generateQr({
    required String courseId,
    required String sessionId,
    required String dosenId,
  }) async {
    return post("presence/qr/generate", {
      "course_id": courseId,
      "session_id": sessionId,
      "dosen_id": dosenId,
      "ts": DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ========== GPS / TELEMETRY ENDPOINTS ==========

  static Future<Map<String, dynamic>> postGps({
    required String deviceId,
    required double lat,
    required double lng,
    required double accuracyM,
  }) async {
    return post(
      "telemetry/gps", 
      {
        "device_id": deviceId,
        "lat": lat,
        "lng": lng,
        "accuracy_m": accuracyM,
        "ts": DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  /// Mengambil data GPS terbaru untuk Marker (GET)
  static Future<Map<String, dynamic>> getGpsLatest(String deviceId) async {
    return get(
      "telemetry/gps/latest",
      queryParams: {"device_id": deviceId},
    );
  }

  /// Mengambil history perjalanan GPS untuk Polyline (GET)
  static Future<Map<String, dynamic>> getGpsHistory(
    String deviceId, {
    int limit = 50,
  }) async {
    return get(
      "telemetry/gps/history",
      queryParams: {"device_id": deviceId, "limit": "$limit"},
    );
  }
}