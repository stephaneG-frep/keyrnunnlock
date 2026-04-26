import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:local_auth/local_auth.dart';

import 'crypto_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  AuthService({
    required SecureStorageService storage,
    required CryptoService crypto,
    LocalAuthentication? localAuthentication,
  })  : _storage = storage,
        _crypto = crypto,
        _localAuth = localAuthentication ?? LocalAuthentication();

  final SecureStorageService _storage;
  final CryptoService _crypto;
  final LocalAuthentication _localAuth;

  Future<bool> hasMasterPassword() async {
    final hash = await _storage.read(SecureStorageService.masterHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> createMasterPassword(String password) async {
    final normalizedPassword = password.trim();
    final masterSalt = _crypto.generateSalt();
    final vaultSalt = _crypto.generateSalt();

    final hash = await _crypto.hashMasterPassword(normalizedPassword, masterSalt);

    await _storage.write(SecureStorageService.masterHashKey, hash);
    await _storage.write(
      SecureStorageService.masterSaltKey,
      base64Encode(masterSalt),
    );
    await _storage.write(
      SecureStorageService.vaultSaltKey,
      base64Encode(vaultSalt),
    );
    await _storage.write(SecureStorageService.vaultSchemaVersionKey, '1');
    await _storage.write(SecureStorageService.lockTimeoutSecondsKey, '60');
  }

  Future<SecretKey?> unlockWithMasterPassword(String password) async {
    final hash = await _storage.read(SecureStorageService.masterHashKey);
    final saltB64 = await _storage.read(SecureStorageService.masterSaltKey);
    final vaultSaltB64 = await _storage.read(SecureStorageService.vaultSaltKey);

    if (hash == null || saltB64 == null || vaultSaltB64 == null) {
      return null;
    }

    var finalPassword = password;
    var isValid = await _crypto.verifyMasterPassword(
      inputPassword: finalPassword,
      salt: base64Decode(saltB64),
      expectedHash: hash,
    );
    if (!isValid) {
      final trimmed = password.trim();
      if (trimmed != password) {
        isValid = await _crypto.verifyMasterPassword(
          inputPassword: trimmed,
          salt: base64Decode(saltB64),
          expectedHash: hash,
        );
        if (isValid) {
          finalPassword = trimmed;
        }
      }
    }
    if (!isValid) return null;

    final key = await _crypto.deriveVaultKey(finalPassword, base64Decode(vaultSaltB64));

    final biometricsEnabled = await isBiometricUnlockEnabled();
    if (biometricsEnabled) {
      await cacheVaultKeyForBiometric(key);
    }

    return key;
  }

  Future<bool> canUseBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final supported = await _localAuth.isDeviceSupported();
    if (!canCheck || !supported) return false;

    final available = await _localAuth.getAvailableBiometrics();
    return available.isNotEmpty;
  }

  Future<bool> authenticateWithBiometrics() {
    return _localAuth.authenticate(
      localizedReason: 'Déverrouille Keyrnunnlock',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }

  Future<void> setBiometricUnlockEnabled(bool enabled) async {
    await _storage.write(
      SecureStorageService.biometricEnabledKey,
      enabled ? '1' : '0',
    );
    if (!enabled) {
      await _storage.delete(SecureStorageService.cachedVaultKey);
    }
  }

  Future<bool> isBiometricUnlockEnabled() async {
    return (await _storage.read(SecureStorageService.biometricEnabledKey)) == '1';
  }

  Future<void> cacheVaultKeyForBiometric(SecretKey key) async {
    final bytes = await key.extractBytes();
    await _storage.write(SecureStorageService.cachedVaultKey, base64Encode(bytes));
  }

  Future<SecretKey?> unlockWithBiometricSessionKey() async {
    final keyData = await _storage.read(SecureStorageService.cachedVaultKey);
    if (keyData == null || keyData.isEmpty) {
      return null;
    }
    return SecretKey(base64Decode(keyData));
  }

  Future<int> getLockTimeoutSeconds() async {
    final raw = await _storage.read(SecureStorageService.lockTimeoutSecondsKey);
    return int.tryParse(raw ?? '') ?? 60;
  }

  Future<void> setLockTimeoutSeconds(int seconds) {
    return _storage.write(SecureStorageService.lockTimeoutSecondsKey, '$seconds');
  }

  Future<void> resetAllData() {
    return _storage.deleteAll();
  }
}
