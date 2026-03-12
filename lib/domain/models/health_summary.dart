/// ──────────────────────────────────────────────────────────────────────────────
/// Health Summary – Domain Model
/// ──────────────────────────────────────────────────────────────────────────────
/// An immutable value object that aggregates the fetched health metrics into a
/// single snapshot.  This is the *only* data structure the UI layer consumes,
/// keeping presentation independent of raw SDK types.
/// ──────────────────────────────────────────────────────────────────────────────
library;

class HealthSummary {
  const HealthSummary({
    required this.totalSteps,
    required this.totalDistanceMeters,
    required this.totalCyclingDistanceMeters,
    required this.totalActiveEnergyBurned,
    required this.totalBasalEnergyBurned,
    required this.totalExerciseTime,
    required this.averageHeartRate,
    required this.averageRestingHeartRate,
    required this.averageHrvSdnn,
    required this.averageBloodPressureSystolic,
    required this.averageBloodPressureDiastolic,
    required this.averageRespiratoryRate,
    required this.latestHeight,
    required this.latestLeanBodyMass,
    required this.totalSleepAsleepMinutes,
    required this.totalSleepInBedMinutes,
    required this.totalSleepAwakeMinutes,
    required this.totalCaloriesConsumed,
    required this.totalSugarGrams,
    required this.totalSodiumGrams,
    required this.totalFiberGrams,
    required this.averageBloodGlucose,
    required this.totalMindfulnessMinutes,
    required this.hasMenstruationFlow,
    required this.startDate,
    required this.endDate,
  });

  /// Total step count.
  final int totalSteps;

  /// Total walking / running distance in **metres**.
  final double totalDistanceMeters;

  /// Total cycling distance in **metres**.
  final double totalCyclingDistanceMeters;

  /// Total active energy burned in **calories**.
  final double totalActiveEnergyBurned;

  /// Total basal energy burned in **calories**.
  final double totalBasalEnergyBurned;

  /// Accumulated exercise duration.
  final Duration totalExerciseTime;

  /// Mean heart rate (bpm) across all data points, or `null` if no data.
  final double? averageHeartRate;

  /// Mean resting heart rate (bpm), or `null` if no data.
  final double? averageRestingHeartRate;

  /// Mean HRV SDNN (ms) across all data points, or `null` if no data.
  final double? averageHrvSdnn;

  /// Mean systolic blood pressure (mmHg), or `null` if no data.
  final double? averageBloodPressureSystolic;

  /// Mean diastolic blood pressure (mmHg), or `null` if no data.
  final double? averageBloodPressureDiastolic;

  /// Mean respiratory rate (respirations/min), or `null` if no data.
  final double? averageRespiratoryRate;

  /// Latest recorded height in **metres**, or `null` if no data.
  final double? latestHeight;

  /// Latest recorded lean body mass in **kilograms**, or `null` if no data.
  final double? latestLeanBodyMass;

  /// Total time spent asleep in **minutes**.
  final double totalSleepAsleepMinutes;

  /// Total time in bed in **minutes** (iOS only).
  final double totalSleepInBedMinutes;

  /// Total time awake during sleep in **minutes**.
  final double totalSleepAwakeMinutes;

  /// Total dietary energy consumed in **kilocalories**.
  final double totalCaloriesConsumed;

  /// Total sugar intake in **grams**.
  final double totalSugarGrams;

  /// Total sodium intake in **grams**.
  final double totalSodiumGrams;

  /// Total fibre intake in **grams**.
  final double totalFiberGrams;

  /// Mean blood glucose level in **mg/dL**, or `null` if no data.
  final double? averageBloodGlucose;

  /// Total mindfulness / meditation time in **minutes** (iOS only).
  final double totalMindfulnessMinutes;

  /// Whether menstruation flow data was recorded in this period.
  final bool hasMenstruationFlow;

  /// The start of the queried date range.
  final DateTime startDate;

  /// The end of the queried date range.
  final DateTime endDate;

  /// Convenience – creates an empty summary for a given range.
  factory HealthSummary.empty({required DateTime startDate, required DateTime endDate}) {
    return HealthSummary(
      totalSteps: 0,
      totalDistanceMeters: 0,
      totalCyclingDistanceMeters: 0,
      totalActiveEnergyBurned: 0,
      totalBasalEnergyBurned: 0,
      totalExerciseTime: Duration.zero,
      averageHeartRate: null,
      averageRestingHeartRate: null,
      averageHrvSdnn: null,
      averageBloodPressureSystolic: null,
      averageBloodPressureDiastolic: null,
      averageRespiratoryRate: null,
      latestHeight: null,
      latestLeanBodyMass: null,
      totalSleepAsleepMinutes: 0,
      totalSleepInBedMinutes: 0,
      totalSleepAwakeMinutes: 0,
      totalCaloriesConsumed: 0,
      totalSugarGrams: 0,
      totalSodiumGrams: 0,
      totalFiberGrams: 0,
      averageBloodGlucose: null,
      totalMindfulnessMinutes: 0,
      hasMenstruationFlow: false,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Returns `true` when every numeric field is zero / null.
  bool get isEmpty =>
      totalSteps == 0 &&
      totalDistanceMeters == 0 &&
      totalCyclingDistanceMeters == 0 &&
      totalActiveEnergyBurned == 0 &&
      totalBasalEnergyBurned == 0 &&
      totalExerciseTime == Duration.zero &&
      averageHeartRate == null &&
      averageRestingHeartRate == null &&
      averageHrvSdnn == null &&
      averageBloodPressureSystolic == null &&
      averageBloodPressureDiastolic == null &&
      averageRespiratoryRate == null &&
      latestHeight == null &&
      latestLeanBodyMass == null &&
      totalSleepAsleepMinutes == 0 &&
      totalSleepInBedMinutes == 0 &&
      totalSleepAwakeMinutes == 0 &&
      totalCaloriesConsumed == 0 &&
      totalSugarGrams == 0 &&
      totalSodiumGrams == 0 &&
      totalFiberGrams == 0 &&
      averageBloodGlucose == null &&
      totalMindfulnessMinutes == 0 &&
      !hasMenstruationFlow;
}
