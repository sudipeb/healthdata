/// ──────────────────────────────────────────────────────────────────────────────
/// Background Health Service
/// ──────────────────────────────────────────────────────────────────────────────
/// Periodically fetches health data from Health Connect (Android) or HealthKit
/// (iOS) in the background using the `health` package.
///
/// Call [start] once after permissions are granted; call [stop] to cancel the
/// periodic timer.  Subscribers listen to [dataStream] for fresh [HealthSummary]
/// snapshots delivered on each sync cycle.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:health/health.dart';

import '../../core/constants/health_constants.dart';
import '../../core/utils/logger.dart';
import '../../domain/models/health_summary.dart';

class BackgroundHealthService {
  BackgroundHealthService({
    this.syncInterval = const Duration(minutes: 15),
  });

  /// How often to re-fetch data from the platform health store.
  final Duration syncInterval;

  final Health _health = Health();

  Timer? _timer;
  final StreamController<HealthSummary> _controller = StreamController.broadcast();

  /// Stream of fresh [HealthSummary] snapshots emitted on each sync cycle.
  Stream<HealthSummary> get dataStream => _controller.stream;

  /// Whether the background sync timer is currently running.
  bool get isRunning => _timer?.isActive ?? false;

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  /// Starts the periodic background sync.
  ///
  /// Performs an immediate fetch then schedules subsequent fetches on
  /// [syncInterval].  No-op if already running.
  void start() {
    if (isRunning) {
      appLogger.info('BackgroundHealthService already running');
      return;
    }

    appLogger.info('BackgroundHealthService started (interval: $syncInterval)');

    // Immediate first fetch.
    _sync();

    _timer = Timer.periodic(syncInterval, (_) => _sync());
  }

  /// Stops the periodic background sync.
  void stop() {
    _timer?.cancel();
    _timer = null;
    appLogger.info('BackgroundHealthService stopped');
  }

  /// Releases resources. Call this when the service is no longer needed.
  void dispose() {
    stop();
    _controller.close();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sync
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _sync() async {
    appLogger.info('BackgroundHealthService: syncing…');

    try {
      final now = DateTime.now();
      // Fetch the last 24 hours on each background tick.
      final start = now.subtract(const Duration(hours: 24));

      final types = _platformTypes;
      final perms = types.map((_) => HealthDataAccess.READ).toList();

      // Re-verify permissions before each fetch to handle revoked grants.
      final hasPerms = await _health.hasPermissions(types, permissions: perms) ?? false;
      if (!hasPerms) {
        appLogger.warning('BackgroundHealthService: permissions not granted – skipping sync');
        return;
      }

      final raw = await _health.getHealthDataFromTypes(types: types, startTime: start, endTime: now);
      final unique = Health().removeDuplicates(raw);

      appLogger.info('BackgroundHealthService: ${unique.length} unique data points fetched');

      final summary = _aggregate(unique, start, now);
      _controller.add(summary);
    } catch (e, st) {
      appLogger.severe('BackgroundHealthService sync failed', e, st);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Aggregation
  // ──────────────────────────────────────────────────────────────────────────

  HealthSummary _aggregate(List<HealthDataPoint> points, DateTime start, DateTime end) {
    int totalSteps = 0;
    double totalDistance = 0;
    double totalCyclingDistance = 0;
    double totalActiveEnergy = 0;
    double totalBasalEnergy = 0;
    double totalExerciseMinutes = 0;
    double totalCalories = 0;
    double totalSugar = 0;
    double totalSodium = 0;
    double totalFiber = 0;
    double totalSleepAsleep = 0;
    double totalSleepInBed = 0;
    double totalSleepAwake = 0;
    double totalMindfulness = 0;
    bool hasMenstruation = false;

    final heartRateValues = <double>[];
    final restingHeartRateValues = <double>[];
    final hrvValues = <double>[];
    final systolicValues = <double>[];
    final diastolicValues = <double>[];
    final respiratoryRateValues = <double>[];
    final bloodGlucoseValues = <double>[];

    double? latestHeight;
    DateTime? latestHeightDate;
    double? latestLeanBodyMass;
    DateTime? latestLeanBodyMassDate;

    for (final point in points) {
      final numericValue = _numericValue(point);

      switch (point.type) {
        case HealthDataType.STEPS:
          totalSteps += (numericValue ?? 0).round();
        case HealthDataType.DISTANCE_WALKING_RUNNING:
        case HealthDataType.DISTANCE_DELTA:
          totalDistance += numericValue ?? 0;
        case HealthDataType.DISTANCE_CYCLING:
          totalCyclingDistance += numericValue ?? 0;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          totalActiveEnergy += numericValue ?? 0;
        case HealthDataType.BASAL_ENERGY_BURNED:
          totalBasalEnergy += numericValue ?? 0;
        case HealthDataType.EXERCISE_TIME:
          totalExerciseMinutes += numericValue ?? 0;
        case HealthDataType.WORKOUT:
          totalExerciseMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
        case HealthDataType.HEART_RATE:
          if (numericValue != null) heartRateValues.add(numericValue);
        case HealthDataType.RESTING_HEART_RATE:
          if (numericValue != null) restingHeartRateValues.add(numericValue);
        case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
        case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
          if (numericValue != null) hrvValues.add(numericValue);
        case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
          if (numericValue != null) systolicValues.add(numericValue);
        case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
          if (numericValue != null) diastolicValues.add(numericValue);
        case HealthDataType.RESPIRATORY_RATE:
          if (numericValue != null) respiratoryRateValues.add(numericValue);
        case HealthDataType.HEIGHT:
          if (numericValue != null) {
            if (latestHeightDate == null || point.dateTo.isAfter(latestHeightDate)) {
              latestHeight = numericValue;
              latestHeightDate = point.dateTo;
            }
          }
        case HealthDataType.LEAN_BODY_MASS:
          if (numericValue != null) {
            if (latestLeanBodyMassDate == null || point.dateTo.isAfter(latestLeanBodyMassDate)) {
              latestLeanBodyMass = numericValue;
              latestLeanBodyMassDate = point.dateTo;
            }
          }
        case HealthDataType.SLEEP_ASLEEP:
          totalSleepAsleep += numericValue ?? 0;
        case HealthDataType.SLEEP_IN_BED:
          totalSleepInBed += numericValue ?? 0;
        case HealthDataType.SLEEP_AWAKE:
          totalSleepAwake += numericValue ?? 0;
        case HealthDataType.DIETARY_ENERGY_CONSUMED:
        case HealthDataType.TOTAL_CALORIES_BURNED:
          totalCalories += numericValue ?? 0;
        case HealthDataType.NUTRITION:
          final value = point.value;
          if (value is NutritionHealthValue) {
            totalSugar += value.sugar ?? 0;
            totalSodium += value.sodium ?? 0;
            totalFiber += value.fiber ?? 0;
          }
        case HealthDataType.DIETARY_SUGAR:
          totalSugar += numericValue ?? 0;
        case HealthDataType.DIETARY_SODIUM:
          totalSodium += numericValue ?? 0;
        case HealthDataType.DIETARY_FIBER:
          totalFiber += numericValue ?? 0;
        case HealthDataType.BLOOD_GLUCOSE:
          if (numericValue != null) bloodGlucoseValues.add(numericValue);
        case HealthDataType.MINDFULNESS:
          totalMindfulness += numericValue ?? 0;
        case HealthDataType.MENSTRUATION_FLOW:
          hasMenstruation = true;
        default:
          break;
      }
    }

    double? avg(List<double> v) => v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;

    return HealthSummary(
      totalSteps: totalSteps,
      totalDistanceMeters: totalDistance,
      totalCyclingDistanceMeters: totalCyclingDistance,
      totalActiveEnergyBurned: totalActiveEnergy,
      totalBasalEnergyBurned: totalBasalEnergy,
      totalExerciseTime: Duration(minutes: totalExerciseMinutes.round()),
      averageHeartRate: avg(heartRateValues),
      averageRestingHeartRate: avg(restingHeartRateValues),
      averageHrvSdnn: avg(hrvValues),
      averageBloodPressureSystolic: avg(systolicValues),
      averageBloodPressureDiastolic: avg(diastolicValues),
      averageRespiratoryRate: avg(respiratoryRateValues),
      latestHeight: latestHeight,
      latestLeanBodyMass: latestLeanBodyMass,
      totalSleepAsleepMinutes: totalSleepAsleep,
      totalSleepInBedMinutes: totalSleepInBed,
      totalSleepAwakeMinutes: totalSleepAwake,
      totalCaloriesConsumed: totalCalories,
      totalSugarGrams: totalSugar,
      totalSodiumGrams: totalSodium,
      totalFiberGrams: totalFiber,
      averageBloodGlucose: avg(bloodGlucoseValues),
      totalMindfulnessMinutes: totalMindfulness,
      hasMenstruationFlow: hasMenstruation,
      startDate: start,
      endDate: end,
    );
  }

  double? _numericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return null;
  }

  List<HealthDataType> get _platformTypes =>
      Platform.isIOS ? kHealthDataTypesIOS : kHealthDataTypesAndroid;
}
