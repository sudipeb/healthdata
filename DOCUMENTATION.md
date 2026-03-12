# Health Data App — Technical Documentation

A complete guide covering how the app reads health data from **Google Fit / Health Connect** (Android) and **Apple HealthKit** (iOS), displays it on a dashboard, and syncs it to a remote server in the background using the **Open Wearables Health SDK**.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Project Dependencies](#2-project-dependencies)
3. [Platform Configuration](#3-platform-configuration)
   - 3.1 [Android — Health Connect](#31-android--health-connect)
   - 3.2 [iOS — HealthKit](#32-ios--healthkit)
4. [App Startup Sequence](#4-app-startup-sequence)
5. [Health Connect Availability Check](#5-health-connect-availability-check)
6. [Permission Request Flow](#6-permission-request-flow)
7. [Fetching Health Data Locally](#7-fetching-health-data-locally)
8. [Data Aggregation Pipeline](#8-data-aggregation-pipeline)
9. [Displaying Data on the Dashboard](#9-displaying-data-on-the-dashboard)
10. [Open Wearables SDK — Background Sync](#10-open-wearables-sdk--background-sync)
    - 10.1 [SDK Initialization](#101-sdk-initialization)
    - 10.2 [Authentication (Sign In)](#102-authentication-sign-in)
    - 10.3 [Provider Selection (Android)](#103-provider-selection-android)
    - 10.4 [Authorization & Starting Sync](#104-authorization--starting-sync)
    - 10.5 [Session Restoration on Restart](#105-session-restoration-on-restart)
    - 10.6 [Log & Auth Error Streams](#106-log--auth-error-streams)
    - 10.7 [Disconnecting](#107-disconnecting)
11. [State Management](#11-state-management)
12. [Complete Data Flow Diagram](#12-complete-data-flow-diagram)
13. [File Reference](#13-file-reference)

---

## 1. Architecture Overview

The app follows a **clean architecture** pattern with three layers:

```
┌───────────────────────────────────────────────────────────┐
│                    Presentation Layer                      │
│  HealthDashboardScreen ← BlocBuilder ← HealthCubit       │
│  MetricCards, DateRangeSelector, sync status icon          │
├───────────────────────────────────────────────────────────┤
│                      Domain Layer                         │
│  HealthRepository (abstract) — HealthSummary model        │
│  Pure Dart, no framework dependencies                     │
├───────────────────────────────────────────────────────────┤
│                       Data Layer                          │
│  HealthRepositoryImpl (health package)                    │
│  OpenWearablesService (open_wearables_health_sdk)         │
│  Talks to Health Connect / HealthKit / remote API         │
└───────────────────────────────────────────────────────────┘
```

There are **two separate health data pipelines** running:

| Pipeline | Purpose | Package | Direction |
|---|---|---|---|
| **Local read** | Read health data from the device and display it on the dashboard | `health` | Device → App UI |
| **Background sync** | Silently push health data to a remote server | `open_wearables_health_sdk` | Device → Remote API |

---

## 2. Project Dependencies

Defined in `pubspec.yaml`:

| Package | Version | Role |
|---|---|---|
| `health` | ^13.3.1 | Reads data from Health Connect (Android) / HealthKit (iOS) |
| `open_wearables_health_sdk` | ^0.0.12 | Background sync to Open Wearables remote API |
| `flutter_bloc` | ^9.1.0 | State management via `HealthCubit` / `HealthState` |
| `equatable` | ^2.0.7 | Value equality for state objects |
| `intl` | ^0.19.0 | Date/time formatting |
| `logging` | ^1.3.0 | Structured logging |

---

## 3. Platform Configuration

### 3.1 Android — Health Connect

**File:** `android/app/src/main/AndroidManifest.xml`

#### Permissions declared

The manifest declares every Health Connect `READ_*` permission the app needs:

```xml
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.READ_DISTANCE" />
<uses-permission android:name="android.permission.health.READ_EXERCISE" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE_VARIABILITY" />
<uses-permission android:name="android.permission.health.READ_NUTRITION" />
<uses-permission android:name="android.permission.health.READ_SLEEP" />
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.READ_BASAL_METABOLIC_RATE" />
<uses-permission android:name="android.permission.health.READ_BODY_FAT" />
<uses-permission android:name="android.permission.health.READ_BODY_TEMPERATURE" />
<uses-permission android:name="android.permission.health.READ_BLOOD_GLUCOSE" />
<uses-permission android:name="android.permission.health.READ_BLOOD_PRESSURE" />
<uses-permission android:name="android.permission.health.READ_HEIGHT" />
<uses-permission android:name="android.permission.health.READ_WEIGHT" />
<uses-permission android:name="android.permission.health.READ_OXYGEN_SATURATION" />
<uses-permission android:name="android.permission.health.READ_RESPIRATORY_RATE" />
<uses-permission android:name="android.permission.health.READ_RESTING_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_VO2_MAX" />
<uses-permission android:name="android.permission.activity_recognition" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### Permission rationale Activity Aliases

Android 12–13 and Android 14+ each require a specific Activity Alias so Health Connect can show a permission rationale screen:

- `ViewPermissionUsageActivity` — Android 14+ (intent action: `VIEW_PERMISSION_USAGE`)
- `ShowPermissionRationaleActivity` — Android 12–13 (intent action: `ACTION_SHOW_PERMISSIONS_RATIONALE`)

#### Health Connect package query

```xml
<queries>
    <package android:name="com.google.android.apps.healthdata" />
</queries>
```

This lets the app check if Health Connect is installed on the device.

#### Build config

- **minSdk:** 29 (Android 10 — the minimum for Health Connect)
- **Core library desugaring:** enabled (for Java 8+ time APIs on API 29)
- **MainActivity:** extends `FlutterFragmentActivity` (required by the health package)

### 3.2 iOS — HealthKit

**File:** `ios/Runner/Info.plist`

#### Privacy descriptions

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app syncs your health data to your account.</string>
```

This string is displayed to the user when HealthKit requests read permission.

#### Background modes

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.openwearables.healthsdk.task.refresh</string>
</array>
```

These enable the Open Wearables SDK to run background sync tasks. The `fetch` mode allows periodic background fetches, and `processing` allows longer background tasks. The `BGTaskSchedulerPermittedIdentifiers` key registers the specific task identifier the SDK uses.

---

## 4. App Startup Sequence

**File:** `lib/main.dart`

When the app launches, `main()` executes these steps **in order**:

```
main()
  │
  ├─ 1. WidgetsFlutterBinding.ensureInitialized()
  │     Ensures Flutter engine is ready before calling async code.
  │
  ├─ 2. initLogging()
  │     Sets up the structured logger used throughout the app.
  │
  ├─ 3. OpenWearablesService(host: '...').init()
  │     Configures the Open Wearables SDK.
  │     Restores any previous user session from secure storage (Keychain/Keystore).
  │     Subscribes to SDK log and auth error streams.
  │
  ├─ 4. runApp(HealthDataApp(openWearablesService: owService))
  │     ├─ Creates HealthRepositoryImpl  →  configures the `health` package singleton
  │     ├─ Creates HealthCubit(repository, openWearablesService)
  │     └─ Mounts HealthDashboardScreen
  │
  └─ 5. HealthDashboardScreen.initState()  →  HealthCubit.initialise()
        This triggers the full availability → permissions → fetch → sync flow.
```

---

## 5. Health Connect Availability Check

**File:** `lib/data/repositories/health_repository_impl.dart` → `checkAvailability()`

This is the **first step** in `HealthCubit.initialise()`.

### Android

```dart
final status = await _health.getHealthConnectSdkStatus();
```

The `health` package queries the system for the Health Connect app (`com.google.android.apps.healthdata`). Three outcomes:

| Status | Meaning | UI result |
|---|---|---|
| `sdkAvailable` | Health Connect is installed and usable | Proceed to permissions |
| Other | Health Connect is not installed | Show `HealthConnectNotInstalledWidget` with Play Store link |
| Exception | Platform not supported | Show dashboard with empty data |

### iOS

HealthKit is always available on iOS, so the check is skipped:

```dart
if (Platform.isIOS) return HealthConnectStatus.available;
```

---

## 6. Permission Request Flow

**File:** `lib/data/repositories/health_repository_impl.dart` → `requestPermissions()` / `hasPermissions()`

After confirming availability, the cubit checks if permissions are already granted:

```
HealthCubit.initialise()
  │
  ├─ hasPermissions()  →  Already granted?  →  YES  →  Skip to fetch
  │
  └─ NO  →  requestPermissions()
             │
             ├─ Granted  →  Proceed to fetch
             └─ Denied   →  Show dashboard with empty data (graceful fallback)
```

### What permissions are requested

Defined in `lib/core/constants/health_constants.dart`:

**Android (`kHealthDataTypesAndroid`):**
- `STEPS`, `DISTANCE_DELTA`, `WORKOUT`, `HEART_RATE`, `HEART_RATE_VARIABILITY_RMSSD`, `TOTAL_CALORIES_BURNED`, `NUTRITION`

**iOS (`kHealthDataTypesIOS`):**
- `STEPS`, `DISTANCE_WALKING_RUNNING`, `EXERCISE_TIME`, `HEART_RATE`, `HEART_RATE_VARIABILITY_SDNN`, `DIETARY_ENERGY_CONSUMED`

All permissions are requested as **READ-only**:

```dart
final perms = types.map((_) => HealthDataAccess.READ).toList();
final granted = await _health.requestAuthorization(types, permissions: perms);
```

On Android this launches the Health Connect permission sheet. On iOS it launches the HealthKit authorization dialog.

---

## 7. Fetching Health Data Locally

**File:** `lib/data/repositories/health_repository_impl.dart` → `fetchHealthData()`

Once permissions are granted, the cubit calls `fetchData()`, which resolves a date range (Today, Last 7 Days, or Custom) and queries the `health` package:

```dart
final dataPoints = await _health.getHealthDataFromTypes(
  types: _platformTypes,    // Android or iOS type list
  startTime: start,
  endTime: end,
);
```

The `health` package communicates with:
- **Android:** Health Connect API (which aggregates data from Google Fit and other providers)
- **iOS:** HealthKit

### Deduplication

The SDK may return overlapping data points (e.g., from multiple sources writing to Health Connect). The app removes duplicates:

```dart
final uniquePoints = Health().removeDuplicates(dataPoints);
```

---

## 8. Data Aggregation Pipeline

**File:** `lib/data/repositories/health_repository_impl.dart` → `_aggregate()`

Raw `HealthDataPoint` objects from the SDK are reduced into a single `HealthSummary`:

```
List<HealthDataPoint>  ──→  _aggregate()  ──→  HealthSummary
```

The aggregation loops through every unique data point and groups by type:

| Data Type(s) | Aggregation | Result field |
|---|---|---|
| `STEPS` | Sum (rounded to int) | `totalSteps` |
| `DISTANCE_WALKING_RUNNING` / `DISTANCE_DELTA` | Sum | `totalDistanceMeters` |
| `EXERCISE_TIME` | Sum (minutes) | `totalExerciseTime` |
| `WORKOUT` | Sum of `dateTo - dateFrom` duration | `totalExerciseTime` |
| `HEART_RATE` | Collect all → compute mean | `averageHeartRate` |
| `HEART_RATE_VARIABILITY_SDNN` / `_RMSSD` | Collect all → compute mean | `averageHrvSdnn` |
| `DIETARY_ENERGY_CONSUMED` / `TOTAL_CALORIES_BURNED` | Sum | `totalCaloriesConsumed` |
| `NUTRITION` (Android) | Extract sub-fields (sugar, sodium, fiber) | `totalSugarGrams`, `totalSodiumGrams`, `totalFiberGrams` |
| `DIETARY_SUGAR` / `DIETARY_SODIUM` / `DIETARY_FIBER` (iOS) | Sum each | Same as above |

### Value extraction

Numeric values are unwrapped from the SDK's `HealthValue` hierarchy:

```dart
double? _extractNumericValue(HealthDataPoint point) {
  final value = point.value;
  if (value is NumericHealthValue) {
    return value.numericValue.toDouble();
  }
  return null;
}
```

Android's `NUTRITION` type bundles multiple sub-values into one `NutritionHealthValue`:

```dart
void _extractNutrition(HealthDataPoint point, Function apply) {
  final value = point.value;
  if (value is NutritionHealthValue) {
    apply(value.sugar ?? 0, value.sodium ?? 0, value.fiber ?? 0, value.calories ?? 0);
  }
}
```

---

## 9. Displaying Data on the Dashboard

**File:** `lib/presentation/screens/health_dashboard_screen.dart`

### Screen status routing

The `BlocBuilder<HealthCubit, HealthState>` pattern-matches on `HealthScreenStatus`:

| Status | Widget shown |
|---|---|
| `initial` / `checkingAvailability` / `loading` | `CircularProgressIndicator` |
| `healthConnectNotInstalled` | `HealthConnectNotInstalledWidget` (install instructions) |
| `permissionDenied` | `PermissionDeniedWidget` (retry button) |
| `error` | `ErrorStateWidget` (error message + retry) |
| `loaded` | Date range selector + metric card grid |

### Metric cards

When status is `loaded`, a 2-column grid of `MetricCard` widgets is displayed:

| Card | Icon | Source field | Unit |
|---|---|---|---|
| Steps | walk icon (blue) | `totalSteps` | steps |
| Walking / Running | route icon (orange) | `totalDistanceMeters` | m or km |
| Exercise Time | timer icon (green) | `totalExerciseTime` | Xh Ym |
| Avg Heart Rate | heart icon (red) | `averageHeartRate` | bpm |
| Avg HRV (SDNN) | chart icon (purple) | `averageHrvSdnn` | ms |
| Calories Consumed | fire icon (deep orange) | `totalCaloriesConsumed` | kcal |
| Sugar | ice cream icon (pink) | `totalSugarGrams` | g |
| Sodium | grain icon (blue grey) | `totalSodiumGrams` | g |
| Fiber | grass icon (teal) | `totalFiberGrams` | g |

### Sync status indicator

The AppBar shows a **sync icon** (green = active, grey = inactive) reflecting whether the Open Wearables background sync is running:

```dart
Icon(Icons.sync_rounded, color: state.isSyncActive ? Colors.green : Colors.grey)
```

### Pull-to-refresh

The entire body is wrapped in a `RefreshIndicator` that calls `HealthCubit.fetchData()` on pull-down.

### Date range selection

A row of chips allows switching between:
- **Today** — midnight today → now
- **Last 7 Days** — 6 days ago → now
- **Custom** — user picks start/end via date picker

Changing the range re-fetches data automatically.

---

## 10. Open Wearables SDK — Background Sync

The Open Wearables SDK runs **independently** from the local data read pipeline. It registers native background observers that push health data to a remote API endpoint, even when the app is not in the foreground.

**File:** `lib/data/services/open_wearables_service.dart`

### 10.1 SDK Initialization

Called once at app startup in `main()`:

```dart
final owService = OpenWearablesService(host: 'https://api.example.com');
await owService.init();
```

Inside `init()`:

```dart
await OpenWearablesHealthSdk.configure(host: host);
```

This does three things:
1. Stores the host URL for constructing API endpoints
2. Checks if a background sync was previously active and restores it
3. Attempts to restore any saved user session from secure storage (Keychain on iOS, Keystore on Android)

After `configure()`, the SDK knows:
- The API base URL (e.g., `https://api.example.com`)
- Whether a user session already exists
- Whether sync was previously active

#### API URL structure

The SDK constructs endpoints from the host automatically:

| Endpoint | URL |
|---|---|
| Health data sync | `{host}/api/v1/sdk/users/{userId}/sync` |
| Token refresh | `{host}/api/v1/token/refresh` |

### 10.2 Authentication (Sign In)

After the dashboard is loaded and the Health Connect flow completes, you connect to Open Wearables by calling:

```dart
context.read<HealthCubit>().connectOpenWearables(
  userId: 'your-user-id',
  accessToken: 'Bearer your-access-token',
  refreshToken: 'your-refresh-token',
);
```

This calls through to `OpenWearablesService.connect()`, which:

1. **Checks** if already signed in and syncing → skips if so
2. **Signs in** via the SDK:
   ```dart
   await OpenWearablesHealthSdk.signIn(
     userId: userId,
     accessToken: accessToken,
     refreshToken: refreshToken,
   );
   ```
   The SDK stores credentials in secure storage (Keychain/Keystore).
3. Proceeds to provider selection and sync start

#### Alternative: API key auth

```dart
await owService.connectWithApiKey(userId: 'user-id', apiKey: 'your-api-key');
```

This is simpler but does not support automatic token refresh on 401 errors.

### 10.3 Provider Selection (Android)

On Android, multiple health data providers may be available (Samsung Health, Health Connect). The service selects Health Connect explicitly:

```dart
if (Platform.isAndroid) {
  await OpenWearablesHealthSdk.setProvider(AndroidHealthProvider.healthConnect);
}
```

On iOS this is a no-op — HealthKit is the only provider.

### 10.4 Authorization & Starting Sync

The service requests authorization for a broad set of health data types:

```dart
await OpenWearablesHealthSdk.requestAuthorization(
  types: [
    HealthDataType.steps,
    HealthDataType.heartRate,
    HealthDataType.restingHeartRate,
    HealthDataType.heartRateVariabilitySDNN,
    HealthDataType.sleep,
    HealthDataType.workout,
    HealthDataType.activeEnergy,
    HealthDataType.basalEnergy,
    HealthDataType.distanceWalkingRunning,
    HealthDataType.bodyMass,
    HealthDataType.oxygenSaturation,
    HealthDataType.bloodGlucose,
    HealthDataType.bloodPressure,
    HealthDataType.respiratoryRate,
  ],
);
```

Then starts background sync:

```dart
await OpenWearablesHealthSdk.startBackgroundSync();
```

This registers native observers that:
- **iOS:** Use HealthKit's `HKObserverQuery` to detect new data and `BGTaskScheduler` for periodic background processing
- **Android:** Use Health Connect's change notifications and `WorkManager` for scheduled background syncs
- Perform an **initial full export** on first sync
- Subsequently do **incremental syncs** (only new data since last sync)

### 10.5 Session Restoration on Restart

When the app restarts, the `configure()` call in step 10.1 automatically:

1. Reads stored credentials from secure storage
2. Checks if sync was previously active
3. Restores the sync state

In `HealthCubit.initialise()`, after the local data fetch completes:

```dart
await _startOpenWearablesSync();
```

This checks if the service has a restored session and triggers `syncNow()` if sync isn't already active, so the user doesn't need to re-authenticate.

### 10.6 Log & Auth Error Streams

The service subscribes to two native event streams:

**Log stream** — real-time SDK activity:
```dart
MethodChannelOpenWearablesHealthSdk.logStream.listen((message) =>
  appLogger.info('[OW-SDK] $message')
);
```

**Auth error stream** — token expiration / 401 errors:
```dart
MethodChannelOpenWearablesHealthSdk.authErrorStream.listen((error) {
  // error = {'statusCode': 401, 'message': 'Unauthorized'}
  appLogger.warning('OW auth error: ${error['statusCode']} – ${error['message']}');
  onAuthError?.call(error);
});
```

With token-based auth (accessToken + refreshToken), the SDK automatically refreshes the access token on 401. If refresh also fails, the error is emitted on the auth error stream so the app can redirect to login.

### 10.7 Disconnecting

```dart
context.read<HealthCubit>().disconnectOpenWearables();
```

This calls:

```dart
await OpenWearablesHealthSdk.stopBackgroundSync();  // Cancels all background observers
await OpenWearablesHealthSdk.signOut();              // Clears stored credentials
```

---

## 11. State Management

**Files:** `lib/presentation/providers/health_state.dart`, `lib/presentation/providers/health_notifier.dart`

### HealthState

An immutable data class holding all dashboard state:

| Field | Type | Description |
|---|---|---|
| `status` | `HealthScreenStatus` | Current screen lifecycle stage |
| `summary` | `HealthSummary?` | Aggregated health metrics |
| `errorMessage` | `String?` | Error text for display |
| `selectedRange` | `DateRangeOption` | Today / Last 7 Days / Custom |
| `customStart` / `customEnd` | `DateTime?` | Custom date range bounds |
| `healthConnectStatus` | `HealthConnectStatus?` | HC availability result |
| `isSyncActive` | `bool` | Whether OW background sync is running |
| `syncError` | `String?` | Last OW sync error |

### HealthCubit

A `Cubit<HealthState>` that orchestrates all flows:

| Method | Trigger | Effect |
|---|---|---|
| `initialise()` | Screen mount | Full lifecycle: availability → permissions → fetch → OW sync |
| `fetchData()` | Date change, pull-to-refresh | Reads health data for selected range |
| `selectDateRange()` | Chip tap | Changes range and re-fetches |
| `setCustomRange()` | Date picker | Sets custom bounds and re-fetches |
| `retryPermissions()` | Retry button | Re-requests permissions then fetches |
| `connectOpenWearables()` | Auth flow | Signs in to OW and starts background sync |
| `disconnectOpenWearables()` | Sign out | Stops sync and clears OW session |

---

## 12. Complete Data Flow Diagram

```
┌─────────────┐                  ┌──────────────────┐
│  App Launch  │                  │  Google Fit /     │
│  main()      │                  │  Health Connect   │
└──────┬──────┘                  │  (on device)      │
       │                          └────────┬─────────┘
       │                                   │
  ┌────▼─────────────────┐                │
  │ 1. OW SDK configure   │                │
  │    + restore session   │                │
  └────┬─────────────────┘                │
       │                                   │
  ┌────▼─────────────────┐                │
  │ 2. Build widget tree   │                │
  │    + mount dashboard   │                │
  └────┬─────────────────┘                │
       │                                   │
  ┌────▼─────────────────┐                │
  │ 3. Check HC available  │◄───────────────┤  (query availability)
  └────┬─────────────────┘                │
       │                                   │
  ┌────▼─────────────────┐                │
  │ 4. Request permissions │◄───────────────┤  (permission dialog)
  └────┬─────────────────┘                │
       │                                   │
  ┌────▼─────────────────┐                │
  │ 5. Fetch health data   │◄───────────────┘  (read STEPS, HR, etc.)
  │    via `health` pkg     │
  └────┬─────────────────┘
       │
  ┌────▼─────────────────┐
  │ 6. Aggregate into      │
  │    HealthSummary       │
  └────┬─────────────────┘
       │
  ┌────▼─────────────────┐     ┌────────────────────────┐
  │ 7. Display on dash     │     │ 8. OW background sync  │
  │    (metric cards)      │     │    pushes data to      │
  └────────────────────────┘     │    remote API silently  │
                                  └───────────┬────────────┘
                                              │
                                              ▼
                                  ┌────────────────────────┐
                                  │  Remote API Server      │
                                  │  {host}/api/v1/sdk/     │
                                  │  users/{id}/sync        │
                                  └────────────────────────┘
```

**Steps 1–7** are sequential and happen on every app launch.
**Step 8** runs independently in the background via native OS mechanisms.

---

## 13. File Reference

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point — initializes OW SDK, creates cubit, starts app |
| `lib/core/constants/health_constants.dart` | Platform-specific lists of health data types to request |
| `lib/core/utils/logger.dart` | Global structured logger |
| `lib/domain/models/health_summary.dart` | Immutable aggregated health metrics model |
| `lib/domain/models/date_range_option.dart` | Enum for date range selection |
| `lib/domain/repositories/health_repository.dart` | Abstract interface for health data operations |
| `lib/data/repositories/health_repository_impl.dart` | Concrete implementation using `health` package |
| `lib/data/services/open_wearables_service.dart` | Wrapper around Open Wearables SDK for background sync |
| `lib/presentation/providers/health_notifier.dart` | `HealthCubit` — orchestrates all flows |
| `lib/presentation/providers/health_state.dart` | `HealthState` — immutable UI state model |
| `lib/presentation/screens/health_dashboard_screen.dart` | Main dashboard screen |
| `lib/presentation/widgets/metric_card.dart` | Reusable card for a single metric |
| `lib/presentation/widgets/date_range_selector.dart` | Date range chip row + date picker |
| `lib/presentation/widgets/empty_state_widget.dart` | Placeholder when no data |
| `lib/presentation/widgets/error_state_widget.dart` | Error display with retry |
| `lib/presentation/widgets/health_connect_not_installed_widget.dart` | HC install instructions |
| `lib/presentation/widgets/permission_denied_widget.dart` | Permission denied screen |
| `android/app/src/main/AndroidManifest.xml` | Android permissions + HC activity aliases |
| `ios/Runner/Info.plist` | iOS HealthKit descriptions + background modes |
| `android/app/build.gradle.kts` | minSdk 29, desugaring, Kotlin config |
| `android/app/src/main/kotlin/.../MainActivity.kt` | FlutterFragmentActivity (required by health pkg) |
