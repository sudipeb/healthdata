/// ──────────────────────────────────────────────────────────────────────────────
/// Permission Denied Widget
/// ──────────────────────────────────────────────────────────────────────────────
/// Shown when the user has declined the Health Connect permission prompt.
/// Offers a button to re‑trigger the permission flow.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';

class PermissionDeniedWidget extends StatelessWidget {
  const PermissionDeniedWidget({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: theme.colorScheme.tertiary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('Permissions Required', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Health data access was denied. Please grant the required '
              'permissions so the app can display your health metrics.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Grant Permissions'),
            ),
          ],
        ),
      ),
    );
  }
}
