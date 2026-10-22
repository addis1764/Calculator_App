import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../data/services/secure_storage_service.dart';

class PinService {
  final SecureStorageService storageService;

  PinService({required this.storageService});

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  String _generateRandomSalt() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  /// Checks if the user has already configured a vault PIN
  Future<bool> isPinSet() async {
    final hash = await storageService.getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  /// Setup the first vault PIN
  Future<bool> setupPin(String pin) async {
    if (pin.length < 4) return false;
    final salt = _generateRandomSalt();
    final hash = _hashPin(pin, salt);
    await storageService.savePinSalt(salt);
    await storageService.savePinHash(hash);
    await storageService.setVaultInitialized(true);
    return true;
  }

  /// Verify entered PIN against stored salted hash
  Future<bool> verifyPin(String pin) async {
    final storedHash = await storageService.getPinHash();
    final salt = await storageService.getPinSalt();
    if (storedHash == null || salt == null) return false;

    final computedHash = _hashPin(pin, salt);
    return computedHash == storedHash;
  }

  /// Change existing PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;
    return await setupPin(newPin);
  }
}
