// lib/modules/accel/services/accel_service.dart

import '../../../core/services/api_service.dart';
import '../models/accel_sample.dart';

class AccelService {
  /// Mengirim batch data akselerometer ke server menggunakan central ApiService.
  static Future<bool> sendBatch(String deviceId, List<AccelSample> samples) async {
    try {
      final samplesJson = samples.map((s) => s.toJson()).toList();
      
      final response = await ApiService.postAccel(
        deviceId: deviceId,
        samples: samplesJson,
      );
      
      return response["ok"] == true;
    } catch (e) {
      print("Error sendBatch: $e");
      return false;
    }
  }

  /// Mengambil data akselerometer terbaru untuk perangkat tertentu.
  static Future<AccelSample?> getLatest(String deviceId) async {
    try {
      final response = await ApiService.get(
        "telemetry/accel/latest",
        queryParams: {"device_id": deviceId},
      );

      if (response["ok"] == true && response["data"] != null) {
        return AccelSample.fromJson(response["data"]);
      }
      return null;
    } catch (e) {
      print("Error getLatest: $e");
      return null;
    }
  }

  // 👇 Fungsi baru untuk grafik gelombang Admin
  static Future<List<AccelSample>> getHistory(String deviceId, {int limit = 100}) async {
    try {
      final path = "telemetry/accel/history";
      final response = await ApiService.get(path, queryParams: {
        "device_id": deviceId,
        "limit": limit.toString()
      });

      if (response["ok"] == true && response["data"]["items"] != null) {
        final items = response["data"]["items"] as List;
        return items.map((e) => AccelSample.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error getHistory: $e");
      return [];
    }
  }
}