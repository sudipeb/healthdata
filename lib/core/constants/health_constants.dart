/// ──────────────────────────────────────────────────────────────────────────────
/// Health Constants
/// ──────────────────────────────────────────────────────────────────────────────
/// Centralises the Health Connect data types the app cares about and the
/// corresponding permission set.  Keeping these in one place avoids scattering
/// magic strings / enum values across layers.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:health/health.dart';

/// Health Connect (Android) data types.
/// Uses types available on Google Health Connect – e.g. DISTANCE_DELTA
/// instead of the iOS‑only DISTANCE_WALKING_RUNNING.
const List<HealthDataType> kHealthDataTypesAndroid = [
  HealthDataType.STEPS,
  HealthDataType.DISTANCE_DELTA,
  HealthDataType.WORKOUT,
  HealthDataType.HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  HealthDataType.TOTAL_CALORIES_BURNED,
  HealthDataType.NUTRITION,
];

/// HealthKit (iOS) data types.
const List<HealthDataType> kHealthDataTypesIOS = [
  HealthDataType.STEPS,
  HealthDataType.DISTANCE_WALKING_RUNNING,
  HealthDataType.EXERCISE_TIME,
  HealthDataType.HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_SDNN,
  HealthDataType.DIETARY_ENERGY_CONSUMED,
];
