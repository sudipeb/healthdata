/// ──────────────────────────────────────────────────────────────────────────────
/// Empty State Widget
/// ──────────────────────────────────────────────────────────────────────────────
/// A friendly placeholder shown when data was fetched successfully but no
/// health records exist for the selected range.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text('No Health Data', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'No health records were found for the selected date range. '
              'Try a different range or make sure Health Connect has data.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
