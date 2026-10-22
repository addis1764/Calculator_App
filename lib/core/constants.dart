class AppConstants {
  static const String appName = 'Calculator';
  static const String vaultTitle = 'Secret Vault';

  // Storage and file paths
  static const String vaultDirName = 'vault_photos';
  static const String databaseName = 'calc_vault.db';

  // Secure storage keys
  static const String keyPinHash = 'vault_pin_hash';
  static const String keyPinSalt = 'vault_pin_salt';
  static const String keyAesSecret = 'vault_aes_secret';
  static const String keyBiometricEnabled = 'vault_biometric_enabled';
  static const String keyIsInitialized = 'vault_is_initialized';
  static const String keyDeleteOriginalAfterImport = 'vault_delete_original';

  // Secret code trigger (e.g. typing "1234=" opens the vault)
  static const String secretSuffix = '=';
  static const int minPinLength = 4;
  static const int maxPinLength = 8;
}
