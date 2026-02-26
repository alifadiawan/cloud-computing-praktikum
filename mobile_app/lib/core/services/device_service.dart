import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const _keyUserId = 'user_id';
  static const _keyDeviceId = 'device_id';

  /// Returns a persistent unique user ID for this device.
  /// Generated once and stored in SharedPreferences.
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_keyUserId);
    if (userId == null) {
      userId = 'USR-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      await prefs.setString(_keyUserId, userId);
    }
    return userId;
  }

  /// Returns a persistent unique device ID for this device.
  /// Generated once and stored in SharedPreferences.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);
    if (deviceId == null) {
      deviceId = 'DEV-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      await prefs.setString(_keyDeviceId, deviceId);
    }
    return deviceId;
  }
}
