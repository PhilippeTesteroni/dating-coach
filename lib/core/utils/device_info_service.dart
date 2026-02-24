import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for getting stable Device ID using hardware identifiers.
///
/// Android: ANDROID_ID (Settings.Secure.ANDROID_ID) — stable until factory reset.
/// iOS: identifierForVendor — survives app data clear, stored in Keychain.
///
/// Falls back to flutter_secure_storage so the ID survives app data clears.
class DeviceInfoService {
  static const String _key = 'device_id';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _storage;

  DeviceInfoService(this._storage);

  /// Get or generate stable device ID.
  Future<String> getDeviceId() async {
    // Return stored value first (survives app data clear on iOS via Keychain)
    final stored = await _storage.read(key: _key);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    // Generate from hardware
    final deviceId = await _generateDeviceId();

    // Persist in secure storage
    await _storage.write(key: _key, value: deviceId);

    return deviceId;
  }

  Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        const androidIdPlugin = AndroidId();
        final androidId = await androidIdPlugin.getId();

        if (androidId != null && androidId.isNotEmpty) {
          return 'android_$androidId';
        }

        // Fallback: brand + model
        final info = await _deviceInfo.androidInfo;
        final fallback = '${info.brand}_${info.model}_${info.device}'
            .replaceAll(' ', '_')
            .toLowerCase();
        return 'android_$fallback';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return 'ios_${info.identifierForVendor ?? 'unknown'}';
      }
    } catch (_) {
      // ignore, fall through to timestamp fallback
    }

    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clear device ID — call only on account deletion.
  Future<void> clearDeviceId() async {
    await _storage.delete(key: _key);
  }
}
