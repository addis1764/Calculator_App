import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../data/services/secure_storage_service.dart';

class BiometricService {
  final LocalAuthentication _auth;
  final SecureStorageService storageService;

  BiometricService({
    LocalAuthentication? auth,
    required this.storageService,
  }) : _auth = auth ?? LocalAuthentication();

  /// Check if device supports biometrics and has enrolled fingerprints or face
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if user has turned on biometric unlock in settings
  Future<bool> isBiometricEnabledByUser() async {
    return await storageService.isBiometricEnabled();
  }

  /// Request biometric authentication
  Future<bool> authenticate({
    String reason = 'Scan fingerprint or Face to unlock Secret Vault',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
