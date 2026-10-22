import 'package:flutter/material.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../vault_controller.dart';

class VaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VaultController controller;
  final VoidCallback onQuickLock;

  const VaultAppBar({
    super.key,
    required this.controller,
    required this.onQuickLock,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (controller.isSelectionMode) {
      return AppBar(
        backgroundColor: AppTheme.vaultSurface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: controller.exitSelectionMode,
        ),
        title: Text('${controller.selectedCount} selected'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: 'Select All',
            onPressed: controller.selectAll,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export Selected',
            onPressed: controller.selectedCount == 0
                ? null
                : () async {
                    final confirm = await ConfirmDialog.show(
                      context,
                      title: 'Export Photos',
                      message:
                          'Export and unhide ${controller.selectedCount} selected photos to your device?',
                      confirmText: 'Export',
                      icon: Icons.share_outlined,
                    );
                    if (confirm) {
                      await controller.exportSelected();
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.vaultDanger),
            tooltip: 'Delete Selected',
            onPressed: controller.selectedCount == 0
                ? null
                : () async {
                    final confirm = await ConfirmDialog.show(
                      context,
                      title: 'Delete Photos',
                      message:
                          'Permanently delete ${controller.selectedCount} photos from the vault? This cannot be undone.',
                      confirmText: 'Delete',
                      isDestructive: true,
                      icon: Icons.delete_forever_outlined,
                    );
                    if (confirm) {
                      await controller.deleteSelected();
                    }
                  },
          ),
        ],
      );
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Secret Vault',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${controller.photos.length} ${controller.photos.length == 1 ? "photo" : "photos"}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.lock_outline, color: AppTheme.vaultAccent),
          tooltip: 'Quick Lock (Disguise)',
          onPressed: onQuickLock,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
      ],
    );
  }
}
