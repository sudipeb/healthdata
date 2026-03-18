/// ──────────────────────────────────────────────────────────────────────────────
/// Health State – Presentation Model
/// ──────────────────────────────────────────────────────────────────────────────
/// Represents every possible UI state the health dashboard can be in.
/// Using a sealed‑style enum + data class approach keeps the UI layer pure –
/// it simply pattern‑matches on the current state.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:healthdata/features/health/domain/models/date_range_option.dart';
import 'package:healthdata/features/health/domain/models/health_summary.dart';
import 'package:healthdata/features/health/domain/repositories/health_repository.dart';

/// Describes the overall status of the health screen.
enum HealthScreenStatus {
  /// Initial state – nothing has been attempted yet.
  initial,

  /// Checking Health Connect availability / permissions.
  checkingAvailability,

  /// Health Connect is not installed on the device.
  healthConnectNotInstalled,

  /// The user denied one or more permissions.
  permissionDenied,

  /// Data is being fetched from Health Connect.
  loading,

  /// Data was fetched successfully (may still be empty).
  loaded,

  /// An unrecoverable error occurred.
  error,
}

class HealthState {
  const HealthState({
    this.status = HealthScreenStatus.initial,
    this.summary,
    this.errorMessage,
    this.selectedRange = DateRangeOption.today,
    this.customStart,
    this.customEnd,
    this.healthConnectStatus,
    this.isSyncActive = false,
  });

  final HealthScreenStatus status;
  final HealthSummary? summary;
  final String? errorMessage;
  final DateRangeOption selectedRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final HealthConnectStatus? healthConnectStatus;

  /// Whether Open Wearables background sync is running.
  final bool isSyncActive;

  /// Immutable copy helper.
  HealthState copyWith({
    HealthScreenStatus? status,
    HealthSummary? summary,
    String? errorMessage,
    DateRangeOption? selectedRange,
    DateTime? customStart,
    DateTime? customEnd,
    HealthConnectStatus? healthConnectStatus,
    bool? isSyncActive,
  }) {
    return HealthState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedRange: selectedRange ?? this.selectedRange,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      healthConnectStatus: healthConnectStatus ?? this.healthConnectStatus,
      isSyncActive: isSyncActive ?? this.isSyncActive,
    );
  }
}
