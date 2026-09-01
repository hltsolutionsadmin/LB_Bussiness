import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:local_basket_business/core/services/app_update_service.dart';

/// Shows the update prompt. Returns when the user dismisses an *optional*
/// update; a *forced* update never returns (the dialog cannot be dismissed).
Future<void> showAppUpdateDialog(
  BuildContext context,
  AppUpdateInfo info,
) {
  final forced = info.type == AppUpdateType.forced;
  return showDialog<void>(
    context: context,
    barrierDismissible: !forced,
    builder: (ctx) => PopScope(
      canPop: !forced,
      child: _AppUpdateDialog(info: info, forced: forced),
    ),
  );
}

class _AppUpdateDialog extends StatelessWidget {
  const _AppUpdateDialog({required this.info, required this.forced});

  final AppUpdateInfo info;
  final bool forced;

  Future<void> _openStore() async {
    final uri = Uri.tryParse(info.storeUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final notes = info.releaseNotes.trim();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.system_update_rounded, color: Color(0xFFFF7A00)),
          const SizedBox(width: 10),
          Text(forced ? 'Update required' : 'Update available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            forced
                ? 'This version is no longer supported. Please update to version '
                    '${info.latestVersion} to continue.'
                : 'A new version (${info.latestVersion}) of Local Basket '
                    'Business is available.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              "What's new",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              notes,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
      actions: [
        if (!forced)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        ElevatedButton(
          onPressed: _openStore,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A00),
            foregroundColor: Colors.white,
          ),
          child: const Text('Update now'),
        ),
      ],
    );
  }
}
