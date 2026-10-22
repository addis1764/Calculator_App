import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/hidden_photo.dart';
import '../vault_controller.dart';

class PhotoTile extends StatelessWidget {
  final HiddenPhoto photo;
  final VaultController controller;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PhotoTile({
    super.key,
    required this.photo,
    required this.controller,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.selectedIds.contains(photo.id);

    return Hero(
      tag: 'photo_${photo.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.vaultAccent : AppTheme.vaultBorder,
                width: isSelected ? 2.5 : 1,
              ),
              color: AppTheme.vaultSurface,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Decrypted thumbnail display
                FutureBuilder<Uint8List?>(
                  future: controller.getPhotoBytes(photo),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Icon(Icons.broken_image_outlined, color: AppTheme.vaultDanger),
                      );
                    }
                    return Container(
                      color: AppTheme.vaultSurfaceLight,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                ),
                // Gradient overlay for visual polish
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Selection badge
                if (controller.isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.vaultAccent
                            : Colors.black.withValues(alpha: 0.5),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white70,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
