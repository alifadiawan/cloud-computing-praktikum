import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/base_url.dart';

class TelemetryService {
  /// Sends GPS coordinates to the specific GPS Web App URL.
  static Future<Map<String, dynamic>> postGps({
    required String userId,
    required String deviceId,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse("${AppConfig.gpsBaseUrl}?path=telemetry/gps");
    
    final body = {
      "user_id": userId,
      "device_id": deviceId,
      "lat": lat,
      "lng": lng,
      "ts": DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        body: jsonEncode(body),
      );

      // Handle GAS redirects (302) if they happen
      if (response.statusCode == 302) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          final retryResponse = await http.post(
            Uri.parse(newUrl),
            body: jsonEncode(body),
          );
          return jsonDecode(retryResponse.body);
        }
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {"ok": false, "error": e.toString()};
    }
  }
}
