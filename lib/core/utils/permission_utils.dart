import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Request gallery / photos access permissions depending on platform and OS version
  static Future<bool> requestPhotoPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isAndroid) {
      // Android 13+ (API 33+) requires Permission.photos
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      // Android 12 and lower uses Permission.storage
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }

      // Fallback: Check if already granted or permanently denied
      if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
        return true;
      }

      return false;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    return true;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
