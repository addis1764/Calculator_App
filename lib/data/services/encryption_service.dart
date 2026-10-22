import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'secure_storage_service.dart';

class EncryptionService {
  final SecureStorageService storageService;
  enc.Key? _cachedKey;

  EncryptionService({required this.storageService});

  /// Retrieves or generates the 256-bit AES master key
  Future<enc.Key> _getOrCreateMasterKey() async {
    if (_cachedKey != null) return _cachedKey!;

    String? keyBase64 = await storageService.getAesKey();
    if (keyBase64 == null || keyBase64.isEmpty) {
      final newKey = enc.Key.fromSecureRandom(32);
      keyBase64 = base64Encode(newKey.bytes);
      await storageService.saveAesKey(keyBase64);
      _cachedKey = newKey;
      return newKey;
    }

    _cachedKey = enc.Key(base64Decode(keyBase64));
    return _cachedKey!;
  }

  /// Encrypts raw bytes and prepends the random 16-byte IV
  Future<Uint8List> encryptBytes(Uint8List plainBytes) async {
    final key = await _getOrCreateMasterKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  /// Encrypts an image file and writes the encrypted payload to [targetPath]
  Future<File> encryptFile(File sourceFile, String targetPath) async {
    final bytes = await sourceFile.readAsBytes();
    final encryptedBytes = await encryptBytes(bytes);
    final targetFile = File(targetPath);
    return await targetFile.writeAsBytes(encryptedBytes, flush: true);
  }

  /// Decrypts encrypted file bytes back to raw image bytes in memory
  Future<Uint8List> decryptFileToBytes(String encryptedPath) async {
    final file = File(encryptedPath);
    if (!await file.exists()) {
      throw Exception('Encrypted file not found at $encryptedPath');
    }

    final rawBytes = await file.readAsBytes();
    if (rawBytes.length < 16) {
      throw Exception('Corrupted encrypted file.');
    }

    final key = await _getOrCreateMasterKey();
    final iv = enc.IV(rawBytes.sublist(0, 16));
    final cipherBytes = rawBytes.sublist(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decryptedList = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    return Uint8List.fromList(decryptedList);
  }

  /// Decrypts an encrypted photo to a temporary unencrypted file (useful for export or share)
  Future<File> decryptFileToTemp(String encryptedPath, String originalName) async {
    final decryptedBytes = await decryptFileToBytes(encryptedPath);
    final tempDir = await Directory.systemTemp.createTemp('vault_unhide_');
    final tempFile = File('${tempDir.path}/$originalName');
    return await tempFile.writeAsBytes(decryptedBytes, flush: true);
  }
}
