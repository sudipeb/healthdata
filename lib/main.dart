/// ──────────────────────────────────────────────────────────────────────────────
/// App Entry Point
/// ──────────────────────────────────────────────────────────────────────────────
/// Sets up logging, creates the [HealthRepositoryImpl], and provides the
/// [HealthCubit] to the widget tree via [BlocProvider].
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/utils/logger.dart';
import 'data/repositories/health_repository_impl.dart';
import 'data/services/open_wearables_service.dart';
import 'presentation/providers/health_notifier.dart';
import 'presentation/screens/health_dashboard_screen.dart';

/// TODO: Replace with your actual Open Wearables API host.
const _openWearablesHost = 'https://api.example.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();
  appLogger.info('App starting');

  // Configure the Open Wearables SDK early so any previous session is restored.
  final owService = OpenWearablesService(host: _openWearablesHost);
  await owService.init();

  runApp(HealthDataApp(openWearablesService: owService));
}

class HealthDataApp extends StatelessWidget {
  const HealthDataApp({super.key, required this.openWearablesService});

  final OpenWearablesService openWearablesService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Create the repository once and inject it into the cubit.
      create: (_) => HealthCubit(HealthRepositoryImpl(), openWearablesService: openWearablesService),
      child: MaterialApp(
        title: 'Health Data',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HealthDashboardScreen(),
      ),
    );
  }
}
