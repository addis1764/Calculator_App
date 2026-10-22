import 'package:flutter/foundation.dart';
import '../../core/utils/file_utils.dart';
import '../../data/models/hidden_photo.dart';
import '../../data/repositories/photo_repository.dart';

class VaultController extends ChangeNotifier {
  final PhotoRepository repository;

  List<HiddenPhoto> _photos = [];
  bool _isLoading = false;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  final Map<String, Uint8List> _thumbnailCache = {};

  VaultController({required this.repository});

  List<HiddenPhoto> get photos => List.unmodifiable(_photos);
  bool get isLoading => _isLoading;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedIds.length;

  Future<void> loadPhotos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _photos = await repository.getPhotos();
    } catch (_) {
      _photos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importPhotos(
    List<String> paths, {
    bool deleteOriginal = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newPhotos = await repository.importPhotos(
        paths,
        deleteOriginal: deleteOriginal,
      );
      _photos = [...newPhotos, ..._photos];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> getPhotoBytes(HiddenPhoto photo) async {
    if (_thumbnailCache.containsKey(photo.id)) {
      return _thumbnailCache[photo.id];
    }
    try {
      final bytes = await repository.getDecryptedBytes(photo);
      _thumbnailCache[photo.id] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePhoto(HiddenPhoto photo) async {
    await repository.deletePhoto(photo);
    _photos.removeWhere((p) => p.id == photo.id);
    _thumbnailCache.remove(photo.id);
    _selectedIds.remove(photo.id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    final targets = _photos.where((p) => _selectedIds.contains(p.id)).toList();
    for (final photo in targets) {
      await repository.deletePhoto(photo);
      _thumbnailCache.remove(photo.id);
    }
    _photos.removeWhere((p) => _selectedIds.contains(p.id));
    exitSelectionMode();
  }

  Future<void> exportSelected() async {
    final targets = _photos.where((p) => _selectedIds.contains(p.id)).toList();
    for (final photo in targets) {
      await repository.exportOrSharePhoto(photo);
    }
    exitSelectionMode();
  }

  Future<void> exportPhoto(HiddenPhoto photo) async {
    await repository.exportOrSharePhoto(photo);
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedIds.add(id);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_photos.map((p) => p.id));
    _isSelectionMode = true;
    notifyListeners();
  }

  void exitSelectionMode() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  Future<int> getTotalStorageUsed() async {
    return await FileUtils.getVaultTotalSizeBytes();
  }
}
