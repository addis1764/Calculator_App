import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../core/utils/file_utils.dart';
import '../models/hidden_photo.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class PhotoRepository {
  final DatabaseService dbService;
  final EncryptionService encryptionService;

  PhotoRepository({
    required this.dbService,
    required this.encryptionService,
  });

  /// Fetch all photos from the database
  Future<List<HiddenPhoto>> getPhotos() async {
    return await dbService.getAllPhotos();
  }

  /// Import photos from file paths into the encrypted vault
  Future<List<HiddenPhoto>> importPhotos(
    List<String> filePaths, {
    bool deleteOriginal = false,
  }) async {
    final vaultDir = await FileUtils.getVaultDirectory();
    final List<HiddenPhoto> imported = [];

    for (int i = 0; i < filePaths.length; i++) {
      final sourcePath = filePaths[i];
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) continue;

      final originalName = p.basename(sourcePath);
      final id = 'photo_${DateTime.now().millisecondsSinceEpoch}_$i';
      final encryptedFileName = '$id.enc';
      final encryptedPath = p.join(vaultDir.path, encryptedFileName);

      // Encrypt the file into the vault folder
      await encryptionService.encryptFile(sourceFile, encryptedPath);

      final photo = HiddenPhoto(
        id: id,
        encryptedPath: encryptedPath,
        originalName: originalName,
        dateAdded: DateTime.now(),
        fileSize: await sourceFile.length(),
      );

      await dbService.insertPhoto(photo);
      imported.add(photo);

      // Optionally remove the unencrypted original from gallery
      if (deleteOriginal) {
        await FileUtils.deleteFileSafely(sourcePath);
      }
    }

    return imported;
  }

  /// Decrypts photo into in-memory bytes for display
  Future<Uint8List> getDecryptedBytes(HiddenPhoto photo) async {
    return await encryptionService.decryptFileToBytes(photo.encryptedPath);
  }

  /// Deletes a hidden photo permanently from disk and database
  Future<void> deletePhoto(HiddenPhoto photo) async {
    await FileUtils.deleteFileSafely(photo.encryptedPath);
    await dbService.deletePhoto(photo.id);
  }

  /// Exports or unhides a photo by decrypting to temp and opening system share/save sheet
  Future<void> exportOrSharePhoto(HiddenPhoto photo) async {
    final tempFile = await encryptionService.decryptFileToTemp(
      photo.encryptedPath,
      photo.originalName,
    );
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      text: 'Exported from Secret Vault: ${photo.originalName}',
    );
  }
}
