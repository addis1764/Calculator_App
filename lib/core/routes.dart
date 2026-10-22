import 'package:flutter/material.dart';
import '../features/calculator/calculator_screen.dart';
import '../features/auth/setup_pin_screen.dart';
import '../features/vault/vault_home_screen.dart';
import '../features/vault/photo_viewer_screen.dart';
import '../features/vault/import_photos_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/change_pin_screen.dart';
import '../data/models/hidden_photo.dart';

class AppRoutes {
  static const String calculator = '/';
  static const String setupPin = '/setup-pin';
  static const String vaultHome = '/vault-home';
  static const String photoViewer = '/photo-viewer';
  static const String importPhotos = '/import-photos';
  static const String settings = '/settings';
  static const String changePin = '/change-pin';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case calculator:
        return _buildRoute(const CalculatorScreen(), routeSettings);

      case setupPin:
        final bool isFirstTime = (routeSettings.arguments as bool?) ?? true;
        return _buildRoute(SetupPinScreen(isFirstTime: isFirstTime), routeSettings);

      case vaultHome:
        return _buildRoute(const VaultHomeScreen(), routeSettings);

      case photoViewer:
        final args = routeSettings.arguments as Map<String, dynamic>? ?? {};
        final List<HiddenPhoto> photos = (args['photos'] as List<HiddenPhoto>?) ?? [];
        final int initialIndex = (args['initialIndex'] as int?) ?? 0;
        return _buildRoute(
          PhotoViewerScreen(photos: photos, initialIndex: initialIndex),
          routeSettings,
        );

      case importPhotos:
        return _buildRoute(const ImportPhotosScreen(), routeSettings);

      case settings:
        return _buildRoute(const SettingsScreen(), routeSettings);

      case changePin:
        return _buildRoute(const ChangePinScreen(), routeSettings);

      default:
        return _buildRoute(const CalculatorScreen(), routeSettings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        return FadeTransition(
          opacity: curved,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
