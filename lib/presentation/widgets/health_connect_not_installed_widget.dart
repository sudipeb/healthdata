/// ──────────────────────────────────────────────────────────────────────────────
/// Health Connect Not Installed Widget
/// ──────────────────────────────────────────────────────────────────────────────
/// Instructs the user to install Health Connect from the Play Store.
/// On Android 14+ Health Connect is bundled, so this screen rarely appears on
/// modern devices.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:health/health.dart';

class HealthConnectNotInstalledWidget extends StatelessWidget {
  const HealthConnectNotInstalledWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('Health Connect Not Found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'This app requires Health Connect to display your health data. '
              'Please install it from the Google Play Store.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Health().installHealthConnect(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Install Health Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
