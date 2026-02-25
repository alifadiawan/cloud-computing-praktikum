import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/base_url.dart';

class ApiService {
  // ========== GENERIC METHODS ==========

  /// POST request using text/plain to avoid CORS preflight on web
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse("${AppConfig.baseUrl}?path=$path");

    // Use text/plain to avoid CORS preflight (OPTIONS) request
    // GAS still parses the body via JSON.parse(e.postData.contents)
    final response = await http.post(
      url,
      headers: {"Content-Type": "text/plain"},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse("${AppConfig.baseUrl}?path=$path");

    final response = await http.get(url);

    return jsonDecode(response.body);
  }

  // ========== PRESENCE ENDPOINTS ==========

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
}
