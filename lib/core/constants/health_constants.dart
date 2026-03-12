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
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.BASAL_ENERGY_BURNED,
  HealthDataType.WORKOUT,
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  HealthDataType.RESPIRATORY_RATE,
  HealthDataType.HEIGHT,
  HealthDataType.LEAN_BODY_MASS,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.TOTAL_CALORIES_BURNED,
  HealthDataType.NUTRITION,
  HealthDataType.BLOOD_GLUCOSE,
  HealthDataType.MENSTRUATION_FLOW,
];

/// HealthKit (iOS) data types.
const List<HealthDataType> kHealthDataTypesIOS = [
  HealthDataType.STEPS,
  HealthDataType.DISTANCE_WALKING_RUNNING,
  HealthDataType.DISTANCE_CYCLING,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.BASAL_ENERGY_BURNED,
  HealthDataType.EXERCISE_TIME,
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_SDNN,
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  HealthDataType.RESPIRATORY_RATE,
  HealthDataType.HEIGHT,
  HealthDataType.LEAN_BODY_MASS,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_IN_BED,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.DIETARY_ENERGY_CONSUMED,
  HealthDataType.DIETARY_SUGAR,
  HealthDataType.DIETARY_SODIUM,
  HealthDataType.DIETARY_FIBER,
  HealthDataType.BLOOD_GLUCOSE,
  HealthDataType.MINDFULNESS,
  HealthDataType.MENSTRUATION_FLOW,
];
