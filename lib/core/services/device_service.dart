import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'gotcha_device_id';

  /// Gets the unique device ID, generating it if it doesn't exist.
  /// Persisted in secure storage to survive app uninstalls (on iOS)
  /// or just to be more robust.
  static Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: _key);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _key, value: deviceId);
    }
    return deviceId;
  }
}
