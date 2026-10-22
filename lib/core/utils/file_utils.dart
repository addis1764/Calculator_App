import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants.dart';

class FileUtils {
  static Directory? _cachedVaultDir;

  /// Returns the internal secure folder used to store encrypted photos
  static Future<Directory> getVaultDirectory() async {
    if (_cachedVaultDir != null && await _cachedVaultDir!.exists()) {
      return _cachedVaultDir!;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDocDir.path, AppConstants.vaultDirName));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    _cachedVaultDir = vaultDir;
    return vaultDir;
  }

  /// Format file size into human-readable text (e.g. 2.4 MB)
  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = (bytes > 0) ? (bytes.bitLength - 1) ~/ 10 : 0;
    if (i >= suffixes.length) i = suffixes.length - 1;
    double size = bytes / (1 << (i * 10));
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Safely deletes a file if it exists
  static Future<bool> deleteFileSafely(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Get total storage size of all encrypted files in the vault
  static Future<int> getVaultTotalSizeBytes() async {
    try {
      final dir = await getVaultDirectory();
      int total = 0;
      final files = dir.listSync();
      for (var f in files) {
        if (f is File) {
          total += await f.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Creates a temporary file in system cache (used for sharing or exporting)
  static Future<File> createTempFile(String fileName, List<int> bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, fileName));
    return await file.writeAsBytes(bytes, flush: true);
  }
}
