import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService();

  static const masterHashKey = 'master_hash';
  static const masterSaltKey = 'master_salt';
  static const vaultSaltKey = 'vault_salt';
  static const vaultPayloadKey = 'vault_payload';
  static const biometricEnabledKey = 'biometric_enabled';
  static const cachedVaultKey = 'cached_vault_key';
  static const lockTimeoutSecondsKey = 'lock_timeout_seconds';
  static const vaultSchemaVersionKey = 'vault_schema_version';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<void> deleteAll() {
    return _storage.deleteAll();
  }
}
