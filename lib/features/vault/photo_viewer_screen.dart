import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/utils/file_utils.dart';
import '../../data/models/hidden_photo.dart';
import '../../data/repositories/photo_repository.dart';
import '../../data/services/database_service.dart';
import '../../data/services/encryption_service.dart';
import '../../data/services/secure_storage_service.dart';
import '../../shared/widgets/confirm_dialog.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<HiddenPhoto> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<HiddenPhoto> _photos;
  late final PhotoRepository _repository;
  bool _showOverlays = true;
  final Map<String, Uint8List> _loadedCache = {};

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    final storage = SecureStorageService();
    final encryption = EncryptionService(storageService: storage);
    final db = DatabaseService();
    _repository = PhotoRepository(dbService: db, encryptionService: encryption);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleOverlays() {
    setState(() {
      _showOverlays = !_showOverlays;
    });
  }

  Future<Uint8List?> _loadPhotoBytes(HiddenPhoto photo) async {
    if (_loadedCache.containsKey(photo.id)) {
      return _loadedCache[photo.id];
    }
    try {
      final bytes = await _repository.getDecryptedBytes(photo);
      _loadedCache[photo.id] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteCurrentPhoto() async {
    if (_photos.isEmpty) return;
    final photo = _photos[_currentIndex];

    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Photo',
      message: 'Are you sure you want to permanently delete this photo from your vault?',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_forever_outlined,
    );

    if (confirm && mounted) {
      await _repository.deletePhoto(photo);
      _loadedCache.remove(photo.id);

      setState(() {
        _photos.removeAt(_currentIndex);
        if (_photos.isEmpty) {
          Navigator.of(context).pop();
        } else if (_currentIndex >= _photos.length) {
          _currentIndex = _photos.length - 1;
        }
      });
    }
  }

  Future<void> _exportCurrentPhoto() async {
    if (_photos.isEmpty) return;
    final photo = _photos[_currentIndex];
    try {
      await _repository.exportOrSharePhoto(photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export photo: $e'),
            backgroundColor: AppTheme.vaultDanger,
          ),
        );
      }
    }
  }

  void _showPhotoDetails() {
    if (_photos.isEmpty) return;
    final photo = _photos[_currentIndex];
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.vaultSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.vaultBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Photo Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.image_outlined, 'File Name', photo.originalName),
              _buildDetailRow(Icons.calendar_today_outlined, 'Added', dateFormat.format(photo.dateAdded)),
              _buildDetailRow(Icons.data_usage_outlined, 'File Size', FileUtils.formatBytes(photo.fileSize)),
              _buildDetailRow(Icons.lock_outline, 'Encryption', 'AES-256 (CBC)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.vaultAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final currentPhoto = _photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Swipeable zoomable PageView
          GestureDetector(
            onTap: _toggleOverlays,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return FutureBuilder<Uint8List?>(
                  future: _loadPhotoBytes(photo),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data != null) {
                      return InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Center(
                          child: Hero(
                            tag: 'photo_${photo.id}',
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.white38),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.vaultAccent),
                    );
                  },
                );
              },
            ),
          ),
          // Top Overlay Bar
          if (_showOverlays)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  right: 16,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPhoto.originalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_currentIndex + 1} of ${_photos.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      tooltip: 'Details',
                      onPressed: _showPhotoDetails,
                    ),
                  ],
                ),
              ),
            ),
          // Bottom Overlay Bar
          if (_showOverlays)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  top: 16,
                  left: 24,
                  right: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(
                      icon: Icons.share_outlined,
                      label: 'Export',
                      onTap: _exportCurrentPhoto,
                    ),
                    _buildBottomAction(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: AppTheme.vaultDanger,
                      onTap: _deleteCurrentPhoto,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
