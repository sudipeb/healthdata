/// ──────────────────────────────────────────────────────────────────────────────
/// Health Repository – Domain Contract
/// ──────────────────────────────────────────────────────────────────────────────
/// Defines the *interface* the domain / application layer expects.  The
/// concrete implementation lives in the `data` layer and depends on the
/// `health` package.  This inversion keeps the domain completely framework
/// agnostic.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import '../models/health_summary.dart';

/// Possible outcomes when checking Health Connect availability.
enum HealthConnectStatus {
  /// Health Connect is available and usable.
  available,

  /// Health Connect is not installed on the device.
  notInstalled,

  /// The platform is not supported (e.g. iOS, web).
  unsupported,
}

abstract class HealthRepository {
  /// Check whether Health Connect is installed on this device.
  Future<HealthConnectStatus> checkAvailability();

  /// Request the required health permissions.
  /// Returns `true` when **all** permissions were granted.
  Future<bool> requestPermissions();

  /// Returns `true` if permissions were already granted.
  Future<bool> hasPermissions();

  /// Fetch aggregated health data for the given [start]–[end] window.
  Future<HealthSummary> fetchHealthData({required DateTime start, required DateTime end});
}
