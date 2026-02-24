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
      appBar: AppBar(title: const Text('Health Dashboard'), centerTitle: true),
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
      MetricCard(
        icon: Icons.directions_walk_rounded,
        label: 'Walking / Running',
        value: _formatDistance(summary.totalDistanceMeters),
        unit: summary.totalDistanceMeters >= 1000 ? 'km' : 'm',
        iconColor: Colors.orange,
      ),
      MetricCard(
        icon: Icons.timer_outlined,
        label: 'Exercise Time',
        value: _formatDuration(summary.totalExerciseTime),
        iconColor: Colors.green,
      ),
      MetricCard(
        icon: Icons.favorite_rounded,
        label: 'Avg Heart Rate',
        value: summary.averageHeartRate?.toStringAsFixed(0) ?? '—',
        unit: summary.averageHeartRate != null ? 'bpm' : '',
        iconColor: Colors.red,
      ),
      MetricCard(
        icon: Icons.show_chart_rounded,
        label: 'Avg HRV (SDNN)',
        value: summary.averageHrvSdnn?.toStringAsFixed(1) ?? '—',
        unit: summary.averageHrvSdnn != null ? 'ms' : '',
        iconColor: Colors.purple,
      ),
      MetricCard(
        icon: Icons.local_fire_department_rounded,
        label: 'Calories Consumed',
        value: summary.totalCaloriesConsumed.toStringAsFixed(0),
        unit: 'kcal',
        iconColor: Colors.deepOrange,
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
    ];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Formatters
  // ──────────────────────────────────────────────────────────────────────────

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
}
