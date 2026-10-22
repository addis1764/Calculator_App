import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/utils/permission_utils.dart';
import '../../data/repositories/photo_repository.dart';
import '../../data/services/database_service.dart';
import '../../data/services/encryption_service.dart';
import '../../data/services/secure_storage_service.dart';
import 'vault_controller.dart';
import 'widgets/photo_tile.dart';
import 'widgets/vault_app_bar.dart';

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  late final VaultController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final storage = SecureStorageService();
    final encryption = EncryptionService(storageService: storage);
    final db = DatabaseService();
    final repo = PhotoRepository(dbService: db, encryptionService: encryption);

    _controller = VaultController(repository: repo);
    _controller.loadPhotos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _quickLock() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _pickFromGallery() async {
    final hasPerm = await PermissionUtils.requestPhotoPermission();
    if (!hasPerm && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo gallery permission is required to import photos.'),
          backgroundColor: AppTheme.vaultDanger,
        ),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty && mounted) {
        final storage = SecureStorageService();
        final shouldDeleteOriginal = await storage.getDeleteOriginalAfterImport();

        await _controller.importPhotos(
          pickedFiles.map((x) => x.path).toList(),
          deleteOriginal: shouldDeleteOriginal,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully encrypted & hidden ${pickedFiles.length} ${pickedFiles.length == 1 ? "photo" : "photos"}!',
              ),
              backgroundColor: AppTheme.vaultAccentGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import photos: $e'),
            backgroundColor: AppTheme.vaultDanger,
          ),
        );
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    final hasPerm = await PermissionUtils.requestCameraPermission();
    if (!hasPerm && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to capture photos.'),
          backgroundColor: AppTheme.vaultDanger,
        ),
      );
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        await _controller.importPhotos([photo.path], deleteOriginal: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo captured and securely encrypted in Vault!'),
              backgroundColor: AppTheme.vaultAccentGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: AppTheme.vaultDanger,
          ),
        );
      }
    }
  }

  void _showAddPhotoMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.vaultSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.vaultBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.vaultAccent),
                title: const Text('Import from Gallery'),
                subtitle: const Text('Encrypt and hide existing photos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.vaultAccentGreen),
                title: const Text('Capture with Camera'),
                subtitle: const Text('Photo is directly encrypted without saving to gallery', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _takePhotoWithCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: !_controller.isSelectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (_controller.isSelectionMode) {
              _controller.exitSelectionMode();
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.vaultBg,
            appBar: VaultAppBar(
              controller: _controller,
              onQuickLock: _quickLock,
            ),
            body: _buildBody(),
            floatingActionButton: _controller.isSelectionMode
                ? null
                : FloatingActionButton.extended(
                    onPressed: _showAddPhotoMenu,
                    backgroundColor: AppTheme.vaultAccent,
                    icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                    label: const Text(
                      'Hide Photos',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.vaultSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.vaultBorder),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 46,
                  color: AppTheme.vaultAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Vault is Empty',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Photos added here are encrypted with AES-256 and hidden from your phone gallery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _showAddPhotoMenu,
                icon: const Icon(Icons.add),
                label: const Text('Add Photos to Vault'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.loadPhotos,
      color: AppTheme.vaultAccent,
      backgroundColor: AppTheme.vaultSurface,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: _controller.photos.length,
        itemBuilder: (context, index) {
          final photo = _controller.photos[index];
          return PhotoTile(
            photo: photo,
            controller: _controller,
            onTap: () {
              if (_controller.isSelectionMode) {
                _controller.toggleSelection(photo.id);
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.photoViewer,
                  arguments: {
                    'photos': _controller.photos,
                    'initialIndex': index,
                  },
                ).then((_) {
                  _controller.loadPhotos();
                });
              }
            },
            onLongPress: () {
              _controller.toggleSelection(photo.id);
            },
          );
        },
      ),
    );
  }
}
