import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/sync_provider.dart';
import '../../../logic/sync/sync_engine.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final theme = Theme.of(context);

    IconData icon;
    Color color;

    switch (sync.state) {
      case SyncState.syncing:
        icon = LucideIcons.refreshCw;
        color = theme.colorScheme.onSurface;
      case SyncState.completed:
        icon = LucideIcons.cloudCheck;
        color = theme.colorScheme.onSurface.withValues(alpha: 0.6);
      case SyncState.error:
        icon = LucideIcons.cloudOff;
        color = theme.colorScheme.onSurface.withValues(alpha: 0.6);
      case SyncState.idle:
        icon = LucideIcons.cloud;
        color = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    }

    return Icon(icon, size: 20, color: color);
  }
}
