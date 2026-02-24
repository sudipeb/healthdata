/// ──────────────────────────────────────────────────────────────────────────────
/// Health Repository – Concrete Implementation
/// ──────────────────────────────────────────────────────────────────────────────
/// Uses the `health` package to talk to Android Health Connect.
///
/// Responsibilities:
///   • Configure the [Health] singleton.
///   • Check Health Connect availability.
///   • Request / verify permissions.
///   • Fetch raw [HealthDataPoint]s and aggregate them into a [HealthSummary].
///
/// All public methods are guarded with try/catch so that callers never receive
/// raw platform exceptions – errors are logged and re‑thrown as [Exception].
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'dart:io' show Platform;

import 'package:health/health.dart';

import '../../core/constants/health_constants.dart';
import '../../core/utils/logger.dart';
import '../../domain/models/health_summary.dart';
import '../../domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl() {
    // Configure the Health singleton once at construction time.
    Health().configure();
    appLogger.info('HealthRepositoryImpl initialised');
  }

  final Health _health = Health();

  // ──────────────────────────────────────────────────────────────────────────
  // Availability
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<HealthConnectStatus> checkAvailability() async {
    // On iOS, HealthKit is always available (even on the Simulator).
    // The Health Connect SDK status check is Android-only.
    if (Platform.isIOS) {
      appLogger.info('Running on iOS – HealthKit assumed available');
      return HealthConnectStatus.available;
    }

    try {
      final status = await _health.getHealthConnectSdkStatus();
      appLogger.info('Health Connect SDK status: $status');

      if (status == HealthConnectSdkStatus.sdkAvailable) {
        return HealthConnectStatus.available;
      }
      return HealthConnectStatus.notInstalled;
    } catch (e, st) {
      appLogger.warning('checkAvailability failed', e, st);
      return HealthConnectStatus.unsupported;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Permissions
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<bool> requestPermissions() async {
    try {
      final types = _platformTypes;
      final perms = types.map((_) => HealthDataAccess.READ).toList();
      final granted = await _health.requestAuthorization(types, permissions: perms);
      appLogger.info('Permissions granted: $granted');
      return granted;
    } catch (e, st) {
      appLogger.severe('requestPermissions failed', e, st);
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    try {
      final types = _platformTypes;
      final perms = types.map((_) => HealthDataAccess.READ).toList();
      final result = await _health.hasPermissions(types, permissions: perms);
      appLogger.info('Has permissions: $result');
      return result ?? false;
    } catch (e, st) {
      appLogger.warning('hasPermissions check failed', e, st);
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Data Fetching & Aggregation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<HealthSummary> fetchHealthData({required DateTime start, required DateTime end}) async {
    appLogger.info('Fetching health data from $start to $end');

    try {
      final dataPoints = await _health.getHealthDataFromTypes(types: _platformTypes, startTime: start, endTime: end);

      appLogger.info('Received ${dataPoints.length} data points');

      // Remove duplicates the SDK may return.
      final uniquePoints = Health().removeDuplicates(dataPoints);
      appLogger.info('${uniquePoints.length} unique data points after dedup');

      return _aggregate(uniquePoints, start, end);
    } catch (e, st) {
      appLogger.severe('fetchHealthData failed', e, st);
      throw Exception('Failed to fetch health data: $e');
    }
  }

  /// Reduces a list of raw [HealthDataPoint]s into a single [HealthSummary].
  HealthSummary _aggregate(List<HealthDataPoint> points, DateTime start, DateTime end) {
    double totalDistance = 0;
    double totalExerciseMinutes = 0;
    double totalCalories = 0;
    double totalSugar = 0;
    double totalSodium = 0;
    double totalFiber = 0;

    final heartRateValues = <double>[];
    final hrvValues = <double>[];

    for (final point in points) {
      // The SDK wraps values in a HealthValue hierarchy.  For numeric types
      // we resolve to double via NumericHealthValue.
      final numericValue = _extractNumericValue(point);

      switch (point.type) {
        // Distance (iOS: DISTANCE_WALKING_RUNNING, Android: DISTANCE_DELTA)
        case HealthDataType.DISTANCE_WALKING_RUNNING:
        case HealthDataType.DISTANCE_DELTA:
          totalDistance += numericValue ?? 0;

        // Exercise time (iOS: EXERCISE_TIME, Android: via WORKOUT duration)
        case HealthDataType.EXERCISE_TIME:
          totalExerciseMinutes += numericValue ?? 0;
        case HealthDataType.WORKOUT:
          // Workout duration is end‑start in minutes
          totalExerciseMinutes += point.dateTo.difference(point.dateFrom).inMinutes;

        // Heart rate (both platforms)
        case HealthDataType.HEART_RATE:
          if (numericValue != null) heartRateValues.add(numericValue);

        // HRV (iOS: SDNN, Android: RMSSD)
        case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
        case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
          if (numericValue != null) hrvValues.add(numericValue);

        // Calories (iOS: DIETARY_ENERGY_CONSUMED, Android: TOTAL_CALORIES_BURNED)
        case HealthDataType.DIETARY_ENERGY_CONSUMED:
        case HealthDataType.TOTAL_CALORIES_BURNED:
          totalCalories += numericValue ?? 0;

        // Nutrition breakdown (Android: single NUTRITION record, iOS: separate types)
        case HealthDataType.NUTRITION:
          _extractNutrition(point, (sugar, sodium, fiber, cal) {
            totalSugar += sugar;
            totalSodium += sodium;
            totalFiber += fiber;
            // calories may also come from nutrition records
          });
        case HealthDataType.DIETARY_SUGAR:
          totalSugar += numericValue ?? 0;
        case HealthDataType.DIETARY_SODIUM:
          totalSodium += numericValue ?? 0;
        case HealthDataType.DIETARY_FIBER:
          totalFiber += numericValue ?? 0;

        default:
          break;
      }
    }

    final avgHr = heartRateValues.isEmpty ? null : heartRateValues.reduce((a, b) => a + b) / heartRateValues.length;

    final avgHrv = hrvValues.isEmpty ? null : hrvValues.reduce((a, b) => a + b) / hrvValues.length;

    return HealthSummary(
      totalDistanceMeters: totalDistance,
      totalExerciseTime: Duration(minutes: totalExerciseMinutes.round()),
      averageHeartRate: avgHr,
      averageHrvSdnn: avgHrv,
      totalCaloriesConsumed: totalCalories,
      totalSugarGrams: totalSugar,
      totalSodiumGrams: totalSodium,
      totalFiberGrams: totalFiber,
      startDate: start,
      endDate: end,
    );
  }

  /// Safely extracts a [double] from a [HealthDataPoint]'s value.
  double? _extractNumericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    return null;
  }

  /// Extracts nutrition sub‑values from a [NutritionHealthValue] (Android
  /// Health Connect bundles sugar/sodium/fiber into a single NUTRITION record).
  void _extractNutrition(
    HealthDataPoint point,
    void Function(double sugar, double sodium, double fiber, double calories) apply,
  ) {
    final value = point.value;
    if (value is NutritionHealthValue) {
      apply(value.sugar ?? 0, value.sodium ?? 0, value.fiber ?? 0, value.calories ?? 0);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Platform helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the list of [HealthDataType]s appropriate for the current platform.
  /// On iOS some Health Connect–specific types aren't available, so we filter
  /// down to the types HealthKit supports.
  List<HealthDataType> get _platformTypes {
    if (Platform.isIOS) {
      return kHealthDataTypesIOS;
    }
    return kHealthDataTypesAndroid;
  }
}
