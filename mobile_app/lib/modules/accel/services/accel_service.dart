// lib/modules/accel/services/accel_service.dart

import '../../../core/services/api_service.dart';
import '../models/accel_sample.dart';

class AccelService {
  static Future<bool> sendBatch(String deviceId, List<AccelSample> samples) async {
    final body = {
      "device_id": deviceId,
      "ts": DateTime.now().toUtc().toIso8601String(),
      "samples": samples.map((s) => s.toJson()).toList(),
    };

    try {
      final response = await ApiService.post("telemetry/accel", body);
      return response["ok"] == true;
    } catch (e) {
      print("Error sendBatch: $e");
      return false;
    }
  }

  static Future<AccelSample?> getLatest(String deviceId) async {
    try {
      final path = "telemetry/accel/latest&device_id=$deviceId";
      final response = await ApiService.get(path);

      if (response["ok"] == true && response["data"] != null) {
        return AccelSample.fromJson(response["data"]);
      }
      return null;
    } catch (e) {
      print("Error getLatest: $e");
      return null;
    }
  }
}