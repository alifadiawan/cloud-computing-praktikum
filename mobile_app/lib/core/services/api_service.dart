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

  // ========== TELEMETRY ENDPOINTS (MODUL 2) ==========
  // Opsional: Jika Anda memanggil API langsung dari file ini, 
  // Anda bisa menggunakan metode di bawah ini.
  // Namun, jika Anda menggunakan file accel_service.dart yang kita buat sebelumnya, 
  // metode generic post() dan get() di atas saja sudah cukup.

  static Future<Map<String, dynamic>> sendAccelBatch(Map<String, dynamic> body) async {
    return post("telemetry/accel", body);
  }

  static Future<Map<String, dynamic>> getAccelLatest(String deviceId) async {
    // Karena path API GAS menggunakan query parameter (?path=...), 
    // kita gabungkan parameter device_id menggunakan simbol &
    return get("telemetry/accel/latest&device_id=$deviceId");
  }
}