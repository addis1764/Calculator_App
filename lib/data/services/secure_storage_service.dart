import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  Future<String?> getPinHash() async {
    return await _storage.read(key: AppConstants.keyPinHash);
  }

  Future<void> savePinHash(String hash) async {
    await _storage.write(key: AppConstants.keyPinHash, value: hash);
  }

  Future<String?> getPinSalt() async {
    return await _storage.read(key: AppConstants.keyPinSalt);
  }

  Future<void> savePinSalt(String salt) async {
    await _storage.write(key: AppConstants.keyPinSalt, value: salt);
  }

  Future<String?> getAesKey() async {
    return await _storage.read(key: AppConstants.keyAesSecret);
  }

  Future<void> saveAesKey(String keyBase64) async {
    await _storage.write(key: AppConstants.keyAesSecret, value: keyBase64);
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: AppConstants.keyBiometricEnabled);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: AppConstants.keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isVaultInitialized() async {
    final value = await _storage.read(key: AppConstants.keyIsInitialized);
    return value == 'true';
  }

  Future<void> setVaultInitialized(bool initialized) async {
    await _storage.write(
      key: AppConstants.keyIsInitialized,
      value: initialized.toString(),
    );
  }

  Future<bool> getDeleteOriginalAfterImport() async {
    final value = await _storage.read(key: AppConstants.keyDeleteOriginalAfterImport);
    return value == 'true';
  }

  Future<void> setDeleteOriginalAfterImport(bool delete) async {
    await _storage.write(
      key: AppConstants.keyDeleteOriginalAfterImport,
      value: delete.toString(),
    );
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
