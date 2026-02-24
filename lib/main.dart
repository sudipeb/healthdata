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
import 'presentation/providers/health_notifier.dart';
import 'presentation/screens/health_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();
  appLogger.info('App starting');

  runApp(const HealthDataApp());
}

class HealthDataApp extends StatelessWidget {
  const HealthDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Create the repository once and inject it into the cubit.
      create: (_) => HealthCubit(HealthRepositoryImpl()),
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
