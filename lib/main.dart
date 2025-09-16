import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geofence_attendance/pages/homepage.dart';
 import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
 import 'services/dummy_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔹 Run dummy seeder only once
  final prefs = await SharedPreferences.getInstance();
  final alreadySeeded = prefs.getBool('dummy_seeded') ?? false;

  if (!alreadySeeded) {
    await DummySeeder().seedDummyData();
    await prefs.setBool('dummy_seeded', true); // mark as done
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geofence Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home:  HomeScreenWidget(), // Page 1
    );
  }
}




/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'services/dummy_seeder.dart';
import 'pages/geofence_setup_page.dart';
import 'background/background_work.dart';

/// Background task callback - must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("🔄 Background task started: $task");

      // Initialize Firebase for background task
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Run geofence check logic
      await runGeofenceCheck();

      print("✅ Background task completed successfully");
      return Future.value(true);
    } catch (e) {
      print("❌ Background task failed: $e");
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );

  // Register periodic background task for geofence checking
  await Workmanager().registerPeriodicTask(
    "geofence_check_task",
    "geofence_check",
    frequency: const Duration(minutes: 15), // Minimum allowed frequency
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );

  // 🔹 Run dummy seeder only once
  final prefs = await SharedPreferences.getInstance();
  final alreadySeeded = prefs.getBool('dummy_seeded') ?? false;

  if (!alreadySeeded) {
    await DummySeeder().seedDummyData();
    await prefs.setBool('dummy_seeded', true); // mark as done
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geofence Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: GeofenceSetupPage(), // Page 1
    );
  }
}

/// Utility class for managing background tasks
class BackgroundTaskManager {

  /// Start background geofence monitoring
  static Future<void> startGeofenceMonitoring() async {
    await Workmanager().registerPeriodicTask(
      "geofence_check_task",
      "geofence_check",
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
    print("✅ Background geofence monitoring started");
  }

  /// Stop background geofence monitoring
  static Future<void> stopGeofenceMonitoring() async {
    await Workmanager().cancelByUniqueName("geofence_check_task");
    print("🛑 Background geofence monitoring stopped");
  }

  /// Register one-time task for immediate testing
  static Future<void> registerOneTimeTask() async {
    await Workmanager().registerOneOffTask(
      "geofence_test_task",
      "geofence_check",
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    print("🧪 One-time geofence task registered for testing");
  }
}*/