import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:muhasib/features/plans/domain/services/device_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads a hardware-backed identifier when the platform provides one
/// (survives app-data clears), falling back to a persistent random
/// installation ID on web/unsupported platforms.
class DeviceIdentityServiceImpl implements DeviceIdentityService {
  static const String _prefsKey = 'muhasib_device_id';
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String? _cached;

  @override
  Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;
    final hardwareId = kIsWeb ? null : await _readHardwareId();
    _cached = _normalize(hardwareId) ?? await _readOrCreateInstallationId();
    return _cached!;
  }

  Future<String?> _readHardwareId() async {
    try {
      final plugin = DeviceInfoPlugin();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return (await plugin.androidInfo).id;
        case TargetPlatform.iOS:
          return (await plugin.iosInfo).identifierForVendor;
        case TargetPlatform.windows:
          return (await plugin.windowsInfo).deviceId;
        case TargetPlatform.macOS:
          return (await plugin.macOsInfo).systemGUID;
        case TargetPlatform.linux:
          return (await plugin.linuxInfo).machineId;
        case TargetPlatform.fuchsia:
          return null;
      }
    } catch (_) {
      // MissingPluginException in tests/unsupported platforms.
      return null;
    }
  }

  String? _normalize(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<String> _readOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _normalize(prefs.getString(_prefsKey));
    if (existing != null) return existing;

    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
    await prefs.setString(_prefsKey, id);
    return id;
  }
}
