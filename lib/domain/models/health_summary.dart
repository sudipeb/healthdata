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
    required this.totalDistanceMeters,
    required this.totalExerciseTime,
    required this.averageHeartRate,
    required this.averageHrvSdnn,
    required this.totalCaloriesConsumed,
    required this.totalSugarGrams,
    required this.totalSodiumGrams,
    required this.totalFiberGrams,
    required this.startDate,
    required this.endDate,
  });

  /// Total walking / running distance in **metres**.
  final double totalDistanceMeters;

  /// Accumulated exercise duration.
  final Duration totalExerciseTime;

  /// Mean heart rate (bpm) across all data points, or `null` if no data.
  final double? averageHeartRate;

  /// Mean HRV SDNN (ms) across all data points, or `null` if no data.
  final double? averageHrvSdnn;

  /// Total dietary energy consumed in **kilocalories**.
  final double totalCaloriesConsumed;

  /// Total sugar intake in **grams**.
  final double totalSugarGrams;

  /// Total sodium intake in **grams**.
  final double totalSodiumGrams;

  /// Total fibre intake in **grams**.
  final double totalFiberGrams;

  /// The start of the queried date range.
  final DateTime startDate;

  /// The end of the queried date range.
  final DateTime endDate;

  /// Convenience – creates an empty summary for a given range.
  factory HealthSummary.empty({required DateTime startDate, required DateTime endDate}) {
    return HealthSummary(
      totalDistanceMeters: 0,
      totalExerciseTime: Duration.zero,
      averageHeartRate: null,
      averageHrvSdnn: null,
      totalCaloriesConsumed: 0,
      totalSugarGrams: 0,
      totalSodiumGrams: 0,
      totalFiberGrams: 0,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Returns `true` when every numeric field is zero / null.
  bool get isEmpty =>
      totalDistanceMeters == 0 &&
      totalExerciseTime == Duration.zero &&
      averageHeartRate == null &&
      averageHrvSdnn == null &&
      totalCaloriesConsumed == 0 &&
      totalSugarGrams == 0 &&
      totalSodiumGrams == 0 &&
      totalFiberGrams == 0;
}
