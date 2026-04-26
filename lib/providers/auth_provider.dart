import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStage { loading, setup, locked, unlocked }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  AuthStage _stage = AuthStage.loading;
  SecretKey? _sessionKey;
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  int _lockTimeoutSeconds = 60;
  Timer? _inactivityTimer;

  AuthStage get stage => _stage;
  SecretKey? get sessionKey => _sessionKey;
  bool get biometricsAvailable => _biometricsAvailable;
  bool get biometricsEnabled => _biometricsEnabled;
  int get lockTimeoutSeconds => _lockTimeoutSeconds;

  bool get isUnlocked => _stage == AuthStage.unlocked;

  Future<void> init() async {
    final start = DateTime.now();
    const minSplashDuration = Duration(milliseconds: 1400);

    _stage = AuthStage.loading;
    notifyListeners();

    final hasMaster = await _authService.hasMasterPassword();
    _biometricsAvailable = await _authService.canUseBiometrics();
    _biometricsEnabled = await _authService.isBiometricUnlockEnabled();
    _lockTimeoutSeconds = await _authService.getLockTimeoutSeconds();

    final elapsed = DateTime.now().difference(start);
    final remaining = minSplashDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    _stage = hasMaster ? AuthStage.locked : AuthStage.setup;
    notifyListeners();
  }

  Future<bool> createMasterPassword(String password) async {
    await _authService.createMasterPassword(password);
    final key = await _authService.unlockWithMasterPassword(password);
    if (key == null) return false;

    _sessionKey = key;
    _stage = AuthStage.unlocked;
    _startInactivityTimer();
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithPassword(String password) async {
    final key = await _authService.unlockWithMasterPassword(password);
    if (key == null) {
      return false;
    }

    _sessionKey = key;
    _stage = AuthStage.unlocked;
    _startInactivityTimer();
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithBiometrics() async {
    if (!_biometricsAvailable || !_biometricsEnabled) {
      return false;
    }

    final isValidated = await _authService.authenticateWithBiometrics();
    if (!isValidated) return false;

    final key = await _authService.unlockWithBiometricSessionKey();
    if (key == null) return false;

    _sessionKey = key;
    _stage = AuthStage.unlocked;
    _startInactivityTimer();
    notifyListeners();
    return true;
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _authService.setBiometricUnlockEnabled(value);
    if (value && _sessionKey != null) {
      await _authService.cacheVaultKeyForBiometric(_sessionKey!);
    }
    _biometricsEnabled = value;
    notifyListeners();
  }

  Future<void> setLockTimeoutSeconds(int seconds) async {
    _lockTimeoutSeconds = seconds;
    await _authService.setLockTimeoutSeconds(seconds);
    if (isUnlocked) {
      _startInactivityTimer();
    }
    notifyListeners();
  }

  void registerUserActivity() {
    if (!isUnlocked) return;
    _startInactivityTimer();
  }

  void lock() {
    _inactivityTimer?.cancel();
    _sessionKey = null;
    _stage = AuthStage.locked;
    notifyListeners();
  }

  Future<void> resetVault() async {
    _inactivityTimer?.cancel();
    _sessionKey = null;
    await _authService.resetAllData();
    await init();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: _lockTimeoutSeconds), lock);
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
