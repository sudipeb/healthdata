import 'dart:async';
import 'dart:io' show Platform;

import 'package:open_wearables_health_sdk/health_data_type.dart' as ow;
import 'package:open_wearables_health_sdk/open_wearables_health_sdk.dart';

import '../../core/utils/logger.dart';

/// Wraps the Open Wearables Health SDK for background Google Fit / Health
/// Connect syncing. Call [init] once at app startup, then [connect] after
/// the user is authenticated.
class OpenWearablesService {
  OpenWearablesService({required this.host});

  final String host;

  StreamSubscription<String>? _logSub;
  StreamSubscription<Map<String, dynamic>>? _authErrorSub;

  /// Called when the SDK emits an auth error (e.g. 401). The UI layer can
  /// listen to this to redirect to login.
  void Function(Map<String, dynamic> error)? onAuthError;

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  /// Configure the SDK and restore any previous session.
  Future<void> init() async {
    await OpenWearablesHealthSdk.configure(host: host);
    appLogger.info('OpenWearables SDK configured (host=$host)');

    if (OpenWearablesHealthSdk.isSignedIn) {
      appLogger.info('Session restored for ${OpenWearablesHealthSdk.currentUser?.userId}');
    }

    _listenToStreams();
  }

  /// Sign in and start background sync from Health Connect (Google Fit).
  Future<void> connect({required String userId, required String accessToken, required String refreshToken}) async {
    // Skip if already signed in and syncing.
    if (OpenWearablesHealthSdk.isSignedIn && OpenWearablesHealthSdk.isSyncActive) {
      appLogger.info('OpenWearables already connected & syncing');
      return;
    }

    // Sign in (or re-use restored session).
    if (!OpenWearablesHealthSdk.isSignedIn) {
      await OpenWearablesHealthSdk.signIn(userId: userId, accessToken: accessToken, refreshToken: refreshToken);
      appLogger.info('OpenWearables signed in as $userId');
    }

    // Select Health Connect on Android.
    if (Platform.isAndroid) {
      await OpenWearablesHealthSdk.setProvider(AndroidHealthProvider.healthConnect);
    }

    await _startSync();
  }

  /// Sign in with an API key instead of tokens.
  Future<void> connectWithApiKey({required String userId, required String apiKey}) async {
    if (OpenWearablesHealthSdk.isSignedIn && OpenWearablesHealthSdk.isSyncActive) {
      return;
    }

    if (!OpenWearablesHealthSdk.isSignedIn) {
      await OpenWearablesHealthSdk.signIn(userId: userId, apiKey: apiKey);
    }

    if (Platform.isAndroid) {
      await OpenWearablesHealthSdk.setProvider(AndroidHealthProvider.healthConnect);
    }

    await _startSync();
  }

  /// Disconnect – stops sync and signs out.
  Future<void> disconnect() async {
    await OpenWearablesHealthSdk.stopBackgroundSync();
    await OpenWearablesHealthSdk.signOut();
    appLogger.info('OpenWearables disconnected');
  }

  /// Whether the SDK is currently signed in.
  bool get isSignedIn => OpenWearablesHealthSdk.isSignedIn;

  /// Whether background sync is running.
  bool get isSyncActive => OpenWearablesHealthSdk.isSyncActive;

  /// Manually trigger an incremental sync.
  Future<void> syncNow() async {
    await OpenWearablesHealthSdk.syncNow();
  }

  void dispose() {
    _logSub?.cancel();
    _authErrorSub?.cancel();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Internals
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _startSync() async {
    // Request authorization for the health data types we care about.
    await OpenWearablesHealthSdk.requestAuthorization(
      types: [
        ow.HealthDataType.steps,
        ow.HealthDataType.heartRate,
        ow.HealthDataType.restingHeartRate,
        ow.HealthDataType.heartRateVariabilitySDNN,
        ow.HealthDataType.sleep,
        ow.HealthDataType.workout,
        ow.HealthDataType.activeEnergy,
        ow.HealthDataType.basalEnergy,
        ow.HealthDataType.distanceWalkingRunning,
        ow.HealthDataType.bodyMass,
        ow.HealthDataType.oxygenSaturation,
        ow.HealthDataType.bloodGlucose,
        ow.HealthDataType.bloodPressure,
        ow.HealthDataType.respiratoryRate,
      ],
    );

    await OpenWearablesHealthSdk.startBackgroundSync();
    appLogger.info('OpenWearables background sync started');
  }

  void _listenToStreams() {
    _logSub = MethodChannelOpenWearablesHealthSdk.logStream.listen((message) => appLogger.info('[OW-SDK] $message'));

    _authErrorSub = MethodChannelOpenWearablesHealthSdk.authErrorStream.listen((error) {
      appLogger.warning('OW auth error: ${error['statusCode']} – ${error['message']}');
      onAuthError?.call(error);
    });
  }
}
