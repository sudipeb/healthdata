/// ──────────────────────────────────────────────────────────────────────────────
/// App Logger
/// ──────────────────────────────────────────────────────────────────────────────
/// Thin wrapper around `dart:developer` and the `logging` package so that every
/// layer can emit structured log messages without importing platform specifics.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'dart:developer' as dev;

import 'package:logging/logging.dart';

/// Global logger instance for the app.
final Logger appLogger = Logger('HealthData');

/// Call once at app startup to wire [Logger] records to `dart:developer`.
void initLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    dev.log(
      '${record.level.name}: ${record.time}: ${record.message}',
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}
