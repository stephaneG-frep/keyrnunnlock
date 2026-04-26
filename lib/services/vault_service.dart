import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../models/password_entry.dart';
import 'crypto_service.dart';
import 'secure_storage_service.dart';

class VaultService {
  VaultService({
    required SecureStorageService storage,
    required CryptoService crypto,
  })  : _storage = storage,
        _crypto = crypto;

  final SecureStorageService _storage;
  final CryptoService _crypto;

  Future<List<PasswordEntry>> loadEntries(SecretKey key) async {
    final encrypted = await _storage.read(SecureStorageService.vaultPayloadKey);
    if (encrypted == null || encrypted.isEmpty) {
      return <PasswordEntry>[];
    }

    final plainText = await _crypto.decryptText(
      encryptedPayload: encrypted,
      key: key,
    );
    final payload = jsonDecode(plainText) as Map<String, dynamic>;
    final rawEntries = payload['entries'] as List<dynamic>? ?? <dynamic>[];

    return rawEntries
        .map((dynamic item) => PasswordEntry.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveEntries(
    List<PasswordEntry> entries,
    SecretKey key,
  ) async {
    final payload = jsonEncode(<String, dynamic>{
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    });

    final encrypted = await _crypto.encryptText(plainText: payload, key: key);
    await _storage.write(SecureStorageService.vaultPayloadKey, encrypted);
  }
}
