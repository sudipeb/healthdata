/// ──────────────────────────────────────────────────────────────────────────────
/// Health Cubit – Application / Presentation Logic
/// ──────────────────────────────────────────────────────────────────────────────
/// Orchestrates the Health Connect lifecycle:
///   1. Check availability → 2. Request permissions → 3. Fetch & aggregate.
///
/// Extends [Cubit] so flutter_bloc can manage the lifecycle and the
/// UI can react to state changes via BlocBuilder / BlocListener.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/logger.dart';
import '../../domain/models/date_range_option.dart';
import '../../domain/models/health_summary.dart';
import '../../domain/repositories/health_repository.dart';
import 'health_state.dart';

class HealthCubit extends Cubit<HealthState> {
  HealthCubit(this._repository) : super(const HealthState());

  final HealthRepository _repository;

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Entry‑point – call once when the screen is first shown.
  /// Checks availability → requests permissions → fetches data.
  /// On iOS the Health Connect availability check is skipped (HealthKit is
  /// always present). If permissions are denied the dashboard still loads with
  /// empty data so the rest of the UI remains functional.
  Future<void> initialise() async {
    emit(state.copyWith(status: HealthScreenStatus.checkingAvailability));

    // 1. Availability
    final hcStatus = await _repository.checkAvailability();
    emit(state.copyWith(healthConnectStatus: hcStatus));

    if (hcStatus == HealthConnectStatus.notInstalled) {
      emit(state.copyWith(status: HealthScreenStatus.healthConnectNotInstalled));
      appLogger.warning('Health Connect not installed');
      return;
    }

    if (hcStatus == HealthConnectStatus.unsupported) {
      // Health data is completely unavailable – show dashboard with empty data
      // instead of blocking the user.
      appLogger.warning('Health data source unsupported on this device');
      await _fetchDataOrEmpty();
      return;
    }

    // 2. Permissions
    final hasPerms = await _repository.hasPermissions();
    if (!hasPerms) {
      final granted = await _repository.requestPermissions();
      if (!granted) {
        // On iOS simulator permissions always return false, so fall through
        // to show an empty dashboard instead of a dead‑end screen.
        appLogger.warning('Health permissions denied by user');
        await _fetchDataOrEmpty();
        return;
      }
    }

    // 3. Fetch data for the currently selected range.
    await fetchData();
  }

  /// Re‑requests permissions and then fetches data.
  Future<void> retryPermissions() async {
    emit(state.copyWith(status: HealthScreenStatus.checkingAvailability));

    final granted = await _repository.requestPermissions();
    if (!granted) {
      emit(state.copyWith(status: HealthScreenStatus.permissionDenied));
      return;
    }

    await fetchData();
  }

  /// Fetches health data for the currently selected [DateRangeOption].
  Future<void> fetchData() async {
    emit(state.copyWith(status: HealthScreenStatus.loading));

    try {
      final (start, end) = _resolveDateRange();

      final summary = await _repository.fetchHealthData(start: start, end: end);

      emit(state.copyWith(status: HealthScreenStatus.loaded, summary: summary));
    } catch (e, st) {
      appLogger.severe('fetchData failed', e, st);
      emit(state.copyWith(status: HealthScreenStatus.error, errorMessage: e.toString()));
    }
  }

  /// Changes the selected date range and re‑fetches data.
  Future<void> selectDateRange(DateRangeOption option) async {
    emit(state.copyWith(selectedRange: option));
    if (option != DateRangeOption.custom) {
      await fetchData();
    }
  }

  /// Sets a custom date range and fetches data.
  Future<void> setCustomRange(DateTime start, DateTime end) async {
    emit(state.copyWith(selectedRange: DateRangeOption.custom, customStart: start, customEnd: end));
    await fetchData();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Resolves the start/end pair based on the selected range option.
  (DateTime, DateTime) _resolveDateRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (state.selectedRange) {
      case DateRangeOption.today:
        return (todayStart, now);
      case DateRangeOption.last7Days:
        return (todayStart.subtract(const Duration(days: 6)), now);
      case DateRangeOption.custom:
        return (state.customStart ?? todayStart, state.customEnd ?? now);
    }
  }

  /// Tries to fetch health data; on failure emits an empty [HealthSummary]
  /// so the dashboard is still usable (e.g. on iOS Simulator).
  Future<void> _fetchDataOrEmpty() async {
    try {
      await fetchData();
    } catch (_) {
      final (start, end) = _resolveDateRange();
      final empty = HealthSummary.empty(startDate: start, endDate: end);
      emit(state.copyWith(status: HealthScreenStatus.loaded, summary: empty));
    }
  }
}
