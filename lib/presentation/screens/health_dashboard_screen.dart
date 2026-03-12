/// ──────────────────────────────────────────────────────────────────────────────
/// Health Dashboard Screen
/// ──────────────────────────────────────────────────────────────────────────────
/// The primary screen of the app.  It reacts to [HealthState] changes via
/// `BlocBuilder` and delegates all business logic to [HealthCubit].
///
/// Layout:
///   • AppBar with title
///   • Date‑range selector (chips)
///   • 2‑column grid of MetricCards (or a status placeholder)
///   • Pull‑to‑refresh via RefreshIndicator
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/health_summary.dart';
import '../providers/health_notifier.dart';
import '../providers/health_state.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/health_connect_not_installed_widget.dart';
import '../widgets/metric_card.dart';
import '../widgets/permission_denied_widget.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the initialisation flow as soon as the screen mounts.
    context.read<HealthCubit>().initialise();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        centerTitle: true,
        actions: [
          BlocBuilder<HealthCubit, HealthState>(
            buildWhen: (prev, curr) => prev.isSyncActive != curr.isSyncActive,
            builder: (context, state) {
              return Tooltip(
                message: state.isSyncActive ? 'Background sync active' : 'Background sync inactive',
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.sync_rounded, color: state.isSyncActive ? Colors.green : Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HealthCubit, HealthState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HealthCubit>().fetchData(),
            child: _buildBody(context, state),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Body builder – dispatches on [HealthScreenStatus]
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, HealthState state) {
    switch (state.status) {
      case HealthScreenStatus.initial:
      case HealthScreenStatus.checkingAvailability:
      case HealthScreenStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case HealthScreenStatus.healthConnectNotInstalled:
        return const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: HealthConnectNotInstalledWidget(),
        );

      case HealthScreenStatus.permissionDenied:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PermissionDeniedWidget(onRetry: () => context.read<HealthCubit>().retryPermissions()),
        );

      case HealthScreenStatus.error:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorStateWidget(
            message: state.errorMessage ?? 'An unknown error occurred.',
            onRetry: () => context.read<HealthCubit>().fetchData(),
          ),
        );

      case HealthScreenStatus.loaded:
        return _buildLoadedContent(context, state);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Loaded state – date selector + metric grid
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildLoadedContent(BuildContext context, HealthState state) {
    final summary = state.summary;
    final cubit = context.read<HealthCubit>();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Date range chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: DateRangeSelector(
              selected: state.selectedRange,
              customStart: state.customStart,
              customEnd: state.customEnd,
              onSelected: cubit.selectDateRange,
              onCustomRange: cubit.setCustomRange,
            ),
          ),
        ),

        // Either the empty state or the metric grid.
        if (summary == null || summary.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: EmptyStateWidget())
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              delegate: SliverChildListDelegate(_buildMetricCards(summary)),
            ),
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Metric card list
  // ──────────────────────────────────────────────────────────────────────────

  List<Widget> _buildMetricCards(HealthSummary summary) {
    return [
      // Activity
      MetricCard(
        icon: Icons.directions_walk_rounded,
        label: 'Steps',
        value: _formatSteps(summary.totalSteps),
        unit: 'steps',
        iconColor: Colors.blue,
      ),
      MetricCard(
        icon: Icons.route_rounded,
        label: 'Walk / Run Distance',
        value: _formatDistance(summary.totalDistanceMeters),
        unit: summary.totalDistanceMeters >= 1000 ? 'km' : 'm',
        iconColor: Colors.orange,
      ),
      MetricCard(
        icon: Icons.directions_bike_rounded,
        label: 'Cycling Distance',
        value: _formatDistance(summary.totalCyclingDistanceMeters),
        unit: summary.totalCyclingDistanceMeters >= 1000 ? 'km' : 'm',
        iconColor: Colors.amber,
      ),
      MetricCard(
        icon: Icons.local_fire_department_rounded,
        label: 'Active Energy',
        value: summary.totalActiveEnergyBurned.toStringAsFixed(0),
        unit: 'cal',
        iconColor: Colors.deepOrange,
      ),
      MetricCard(
        icon: Icons.whatshot_rounded,
        label: 'Basal Energy',
        value: summary.totalBasalEnergyBurned.toStringAsFixed(0),
        unit: 'cal',
        iconColor: Colors.orange.shade800,
      ),
      MetricCard(
        icon: Icons.timer_outlined,
        label: 'Exercise Time',
        value: _formatDuration(summary.totalExerciseTime),
        iconColor: Colors.green,
      ),

      // Heart & Vitals
      MetricCard(
        icon: Icons.favorite_rounded,
        label: 'Avg Heart Rate',
        value: summary.averageHeartRate?.toStringAsFixed(0) ?? '—',
        unit: summary.averageHeartRate != null ? 'bpm' : '',
        iconColor: Colors.red,
      ),
      MetricCard(
        icon: Icons.favorite_border_rounded,
        label: 'Resting Heart Rate',
        value: summary.averageRestingHeartRate?.toStringAsFixed(0) ?? '—',
        unit: summary.averageRestingHeartRate != null ? 'bpm' : '',
        iconColor: Colors.red.shade300,
      ),
      MetricCard(
        icon: Icons.show_chart_rounded,
        label: 'Avg HRV (SDNN)',
        value: summary.averageHrvSdnn?.toStringAsFixed(1) ?? '—',
        unit: summary.averageHrvSdnn != null ? 'ms' : '',
        iconColor: Colors.purple,
      ),
      MetricCard(
        icon: Icons.monitor_heart_rounded,
        label: 'Blood Pressure',
        value: summary.averageBloodPressureSystolic != null
            ? '${summary.averageBloodPressureSystolic!.toStringAsFixed(0)}/${summary.averageBloodPressureDiastolic?.toStringAsFixed(0) ?? "—"}'
            : '—',
        unit: summary.averageBloodPressureSystolic != null ? 'mmHg' : '',
        iconColor: Colors.red.shade700,
      ),
      MetricCard(
        icon: Icons.air_rounded,
        label: 'Respiratory Rate',
        value: summary.averageRespiratoryRate?.toStringAsFixed(1) ?? '—',
        unit: summary.averageRespiratoryRate != null ? 'br/min' : '',
        iconColor: Colors.cyan,
      ),

      // Body Measurements
      MetricCard(
        icon: Icons.height_rounded,
        label: 'Height',
        value: summary.latestHeight?.toStringAsFixed(2) ?? '—',
        unit: summary.latestHeight != null ? 'm' : '',
        iconColor: Colors.indigo,
      ),
      MetricCard(
        icon: Icons.fitness_center_rounded,
        label: 'Lean Body Mass',
        value: summary.latestLeanBodyMass?.toStringAsFixed(1) ?? '—',
        unit: summary.latestLeanBodyMass != null ? 'kg' : '',
        iconColor: Colors.brown,
      ),

      // Sleep
      MetricCard(
        icon: Icons.bedtime_rounded,
        label: 'Sleep (Asleep)',
        value: _formatMinutes(summary.totalSleepAsleepMinutes),
        iconColor: Colors.indigo.shade300,
      ),
      MetricCard(
        icon: Icons.bed_rounded,
        label: 'Sleep (In Bed)',
        value: _formatMinutes(summary.totalSleepInBedMinutes),
        iconColor: Colors.indigo.shade200,
      ),
      MetricCard(
        icon: Icons.visibility_rounded,
        label: 'Sleep (Awake)',
        value: _formatMinutes(summary.totalSleepAwakeMinutes),
        iconColor: Colors.indigo.shade100,
      ),

      // Nutrition
      MetricCard(
        icon: Icons.restaurant_rounded,
        label: 'Calories Consumed',
        value: summary.totalCaloriesConsumed.toStringAsFixed(0),
        unit: 'kcal',
        iconColor: Colors.deepOrange.shade300,
      ),
      MetricCard(
        icon: Icons.icecream_outlined,
        label: 'Sugar',
        value: summary.totalSugarGrams.toStringAsFixed(1),
        unit: 'g',
        iconColor: Colors.pink,
      ),
      MetricCard(
        icon: Icons.grain_rounded,
        label: 'Sodium',
        value: summary.totalSodiumGrams.toStringAsFixed(1),
        unit: 'g',
        iconColor: Colors.blueGrey,
      ),
      MetricCard(
        icon: Icons.grass_rounded,
        label: 'Fiber',
        value: summary.totalFiberGrams.toStringAsFixed(1),
        unit: 'g',
        iconColor: Colors.teal,
      ),

      // Other
      MetricCard(
        icon: Icons.bloodtype_rounded,
        label: 'Blood Glucose',
        value: summary.averageBloodGlucose?.toStringAsFixed(1) ?? '—',
        unit: summary.averageBloodGlucose != null ? 'mg/dL' : '',
        iconColor: Colors.red.shade900,
      ),
      MetricCard(
        icon: Icons.self_improvement_rounded,
        label: 'Mindfulness',
        value: _formatMinutes(summary.totalMindfulnessMinutes),
        iconColor: Colors.lightBlue,
      ),
      MetricCard(
        icon: Icons.water_drop_rounded,
        label: 'Menstruation',
        value: summary.hasMenstruationFlow ? 'Recorded' : '—',
        iconColor: Colors.pink.shade300,
      ),
    ];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Formatters
  // ──────────────────────────────────────────────────────────────────────────

  /// Formats a step count with commas for readability.
  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  /// Formats a distance in metres – switches to km when ≥ 1 000m.
  String _formatDistance(double metres) {
    if (metres >= 1000) {
      return (metres / 1000).toStringAsFixed(2);
    }
    return metres.toStringAsFixed(0);
  }

  /// Formats a [Duration] as `Xh Ym` or `Ym`.
  String _formatDuration(Duration d) {
    if (d.inMinutes == 0) return '0m';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Formats raw minutes as `Xh Ym` or `Ym`.
  String _formatMinutes(double totalMinutes) {
    if (totalMinutes == 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final minutes = (totalMinutes % 60).round();
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
