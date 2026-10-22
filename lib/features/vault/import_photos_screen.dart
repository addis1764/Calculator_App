import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/utils/permission_utils.dart';
import '../../data/repositories/photo_repository.dart';
import '../../data/services/database_service.dart';
import '../../data/services/encryption_service.dart';
import '../../data/services/secure_storage_service.dart';

class ImportPhotosScreen extends StatefulWidget {
  const ImportPhotosScreen({super.key});

  @override
  State<ImportPhotosScreen> createState() => _ImportPhotosScreenState();
}

class _ImportPhotosScreenState extends State<ImportPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedFiles = [];
  bool _deleteOriginal = false;
  bool _isEncrypting = false;
  late final PhotoRepository _repository;

  @override
  void initState() {
    super.initState();
    final storage = SecureStorageService();
    final encryption = EncryptionService(storageService: storage);
    final db = DatabaseService();
    _repository = PhotoRepository(dbService: db, encryptionService: encryption);

    // Initial pick
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImages();
    });
  }

  Future<void> _pickImages() async {
    final hasPerm = await PermissionUtils.requestPhotoPermission();
    if (!hasPerm && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gallery permission required to select photos.'),
          backgroundColor: AppTheme.vaultDanger,
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedFiles.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select photos: $e'),
            backgroundColor: AppTheme.vaultDanger,
          ),
        );
      }
    }
  }

  Future<void> _startImport() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isEncrypting = true;
    });

    try {
      final paths = _selectedFiles.map((x) => x.path).toList();
      await _repository.importPhotos(paths, deleteOriginal: _deleteOriginal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully encrypted ${_selectedFiles.length} photos!'),
            backgroundColor: AppTheme.vaultAccentGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error encrypting photos: $e'),
            backgroundColor: AppTheme.vaultDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEncrypting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vaultBg,
      appBar: AppBar(
        title: const Text('Import Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Add More',
            onPressed: _isEncrypting ? null : _pickImages,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isEncrypting) ...[
              const LinearProgressIndicator(
                color: AppTheme.vaultAccent,
                backgroundColor: AppTheme.vaultSurface,
              ),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Encrypting and securing photos into vault...',
                  style: TextStyle(color: AppTheme.vaultAccent, fontSize: 13),
                ),
              ),
            ],
            // Switch for Delete Original
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: AppTheme.vaultSurface,
                child: SwitchListTile(
                  title: const Text(
                    'Delete original from phone',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Removes the visible photo from phone gallery after encrypting in vault.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  value: _deleteOriginal,
                  activeThumbColor: AppTheme.vaultAccent,
                  onChanged: _isEncrypting
                      ? null
                      : (val) {
                          setState(() {
                            _deleteOriginal = val;
                          });
                        },
                ),
              ),
            ),
            // Preview list of selected photos
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_search, size: 56, color: AppTheme.vaultBorder),
                          const SizedBox(height: 12),
                          const Text(
                            'No photos selected',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Choose Photos'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(file.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: _isEncrypting
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedFiles.removeAt(index);
                                        });
                                      },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            // Import Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_selectedFiles.isNotEmpty && !_isEncrypting)
                      ? _startImport
                      : null,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(
                    _selectedFiles.isEmpty
                        ? 'Select Photos to Import'
                        : 'Encrypt & Hide ${_selectedFiles.length} Photos',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vaultAccent,
                    disabledBackgroundColor: AppTheme.vaultBorder,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
