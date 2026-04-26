import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );

  final AesGcm _aesGcm = AesGcm.with256bits();

  List<int> generateSalt([int length = 16]) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  Future<String> hashMasterPassword(String password, List<int> salt) async {
    final secretKey = SecretKey(utf8.encode(password));
    final derived = await _pbkdf2.deriveKey(secretKey: secretKey, nonce: salt);
    final bytes = await derived.extractBytes();
    return base64Encode(bytes);
  }

  Future<bool> verifyMasterPassword({
    required String inputPassword,
    required List<int> salt,
    required String expectedHash,
  }) async {
    final currentHash = await hashMasterPassword(inputPassword, salt);
    return currentHash == expectedHash;
  }

  Future<SecretKey> deriveVaultKey(String password, List<int> vaultSalt) {
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: vaultSalt,
    );
  }

  Future<String> encryptText({
    required String plainText,
    required SecretKey key,
  }) async {
    final nonce = _randomNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );

    return jsonEncode(<String, String>{
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    });
  }

  Future<String> decryptText({
    required String encryptedPayload,
    required SecretKey key,
  }) async {
    final payload = jsonDecode(encryptedPayload) as Map<String, dynamic>;
    final secretBox = SecretBox(
      base64Decode(payload['cipherText'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['mac'] as String)),
    );

    final bytes = await _aesGcm.decrypt(secretBox, secretKey: key);
    return utf8.decode(bytes);
  }

  List<int> _randomNonce() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(12, (_) => random.nextInt(256)),
    );
  }
}
