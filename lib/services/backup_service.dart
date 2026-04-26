import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

import '../models/backup_file_info.dart';
import '../models/password_entry.dart';

class BackupService {
  BackupService();

  static const String _backupVersion = 'keyrnunnlock_backup_v1';
  static const int _iterations = 180000;

  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: 256,
  );
  final AesGcm _aesGcm = AesGcm.with256bits();

  Future<String> exportEncryptedBackup({
    required List<PasswordEntry> entries,
    required String exportPassword,
  }) async {
    final backupDir = await _ensureBackupDirectory();
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveExportKey(exportPassword, salt);

    final plainPayload = jsonEncode(<String, dynamic>{
      'schema': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
    });

    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plainPayload),
      secretKey: key,
      nonce: nonce,
    );

    final encryptedPayload = jsonEncode(<String, dynamic>{
      'format': _backupVersion,
      'kdf': <String, dynamic>{
        'algorithm': 'pbkdf2-hmac-sha256',
        'iterations': _iterations,
        'salt': base64Encode(salt),
      },
      'cipher': <String, dynamic>{
        'algorithm': 'aes-256-gcm',
        'nonce': base64Encode(secretBox.nonce),
        'cipherText': base64Encode(secretBox.cipherText),
        'mac': base64Encode(secretBox.mac.bytes),
      },
      'meta': <String, dynamic>{'count': entries.length},
    });

    final filename = _buildBackupFilename();
    final file = File('${backupDir.path}/$filename');
    await file.writeAsString(encryptedPayload, flush: true);
    return file.path;
  }

  Future<List<BackupFileInfo>> listBackups() async {
    final dir = await _ensureBackupDirectory();
    final entities = dir.listSync();

    final files = entities.whereType<File>().where((file) {
      final name = file.path.split(Platform.pathSeparator).last;
      return name.endsWith('.kbl');
    }).toList();

    final backups = <BackupFileInfo>[];
    for (final file in files) {
      final stat = await file.stat();
      final name = file.path.split(Platform.pathSeparator).last;
      backups.add(
        BackupFileInfo(
          name: name,
          path: file.path,
          createdAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  Future<List<PasswordEntry>> importEncryptedBackup({
    required String backupPath,
    required String exportPassword,
  }) async {
    final file = File(backupPath);
    if (!await file.exists()) {
      throw Exception('Fichier de sauvegarde introuvable.');
    }

    final content = await file.readAsString();
    final payload = jsonDecode(content) as Map<String, dynamic>;
    final format = payload['format'] as String?;
    if (format != _backupVersion) {
      throw Exception('Format de sauvegarde non pris en charge.');
    }

    final kdf = payload['kdf'] as Map<String, dynamic>?;
    final cipher = payload['cipher'] as Map<String, dynamic>?;
    if (kdf == null || cipher == null) {
      throw Exception('Sauvegarde corrompue.');
    }

    final salt = base64Decode(kdf['salt'] as String);
    final nonce = base64Decode(cipher['nonce'] as String);
    final cipherText = base64Decode(cipher['cipherText'] as String);
    final mac = base64Decode(cipher['mac'] as String);

    final key = await _deriveExportKey(exportPassword, salt);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));

    String decrypted;
    try {
      final bytes = await _aesGcm.decrypt(secretBox, secretKey: key);
      decrypted = utf8.decode(bytes);
    } on SecretBoxAuthenticationError {
      throw Exception(
        'Mot de passe d\'export incorrect ou sauvegarde invalide.',
      );
    }

    final plainPayload = jsonDecode(decrypted) as Map<String, dynamic>;
    final rawEntries = plainPayload['entries'] as List<dynamic>? ?? <dynamic>[];

    return rawEntries
        .map((item) => PasswordEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Directory> _ensureBackupDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<SecretKey> _deriveExportKey(String password, List<int> salt) {
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  String _buildBackupFilename() {
    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    return 'keyrnunnlock_backup_$timestamp.kbl';
  }
}
