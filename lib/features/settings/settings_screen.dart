import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/utils/file_utils.dart';
import '../../data/services/database_service.dart';
import '../../data/services/secure_storage_service.dart';
import '../auth/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SecureStorageService _storage = SecureStorageService();
  late final BiometricService _biometricService;
  final DatabaseService _db = DatabaseService();

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _deleteOriginal = false;
  int _photoCount = 0;
  int _storageUsedBytes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricService(storageService: _storage);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bioAvail = await _biometricService.isBiometricAvailable();
    final bioEnabled = await _storage.isBiometricEnabled();
    final delOriginal = await _storage.getDeleteOriginalAfterImport();
    final count = await _db.getPhotoCount();
    final size = await FileUtils.getVaultTotalSizeBytes();

    if (mounted) {
      setState(() {
        _biometricAvailable = bioAvail;
        _biometricEnabled = bioEnabled;
        _deleteOriginal = delOriginal;
        _photoCount = count;
        _storageUsedBytes = size;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final success = await _biometricService.authenticate(
        reason: 'Verify identity to enable biometric unlock',
      );
      if (!success) return;
    }

    await _storage.setBiometricEnabled(value);
    setState(() {
      _biometricEnabled = value;
    });
  }

  Future<void> _toggleDeleteOriginal(bool value) async {
    await _storage.setDeleteOriginalAfterImport(value);
    setState(() {
      _deleteOriginal = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vaultBg,
      appBar: AppBar(
        title: const Text('Vault Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSectionHeader('SECURITY'),
                _buildCard([
                  ListTile(
                    leading: const Icon(Icons.password_outlined, color: AppTheme.vaultAccent),
                    title: const Text('Change Secret PIN'),
                    subtitle: const Text('Update your calculator unlock code', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.changePin);
                    },
                  ),
                  if (_biometricAvailable) ...[
                    const Divider(color: AppTheme.vaultBorder, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint, color: AppTheme.vaultAccentGreen),
                      title: const Text('Biometric Unlock'),
                      subtitle: const Text('Unlock using fingerprint or Face ID', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      value: _biometricEnabled,
                      activeThumbColor: AppTheme.vaultAccent,
                      onChanged: _toggleBiometrics,
                    ),
                  ],
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader('PHOTO IMPORT'),
                _buildCard([
                  SwitchListTile(
                    secondary: const Icon(Icons.auto_delete_outlined, color: AppTheme.vaultAccent),
                    title: const Text('Auto-Delete Gallery Originals'),
                    subtitle: const Text('Delete unencrypted photo after import', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    value: _deleteOriginal,
                    activeThumbColor: AppTheme.vaultAccent,
                    onChanged: _toggleDeleteOriginal,
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader('VAULT STORAGE'),
                _buildCard([
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined, color: AppTheme.vaultAccent),
                    title: const Text('Encrypted Photos'),
                    trailing: Text(
                      '$_photoCount',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                  ),
                  const Divider(color: AppTheme.vaultBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined, color: AppTheme.vaultAccent),
                    title: const Text('Storage Space Used'),
                    trailing: Text(
                      FileUtils.formatBytes(_storageUsedBytes),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader('DISGUISE GUIDE'),
                _buildCard([
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text('How to open your vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '1. Open the Calculator app.\n'
                          '2. Type your secret PIN into the calculator.\n'
                          '3. Press "=" to immediately reveal your hidden vault.\n\n'
                          'To anyone else, it is a fully functioning standard calculator!',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: AppTheme.vaultSurface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.vaultBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
