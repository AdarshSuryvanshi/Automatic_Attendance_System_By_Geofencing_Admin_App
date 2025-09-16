import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils.dart';

Future<void> runGeofenceCheck() async {
  try {
    print('Running geofence check...');
    
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('employee_phone');
    if (phone == null) return;

    // Get employee data
    final empSnap = await FirebaseFirestore.instance
        .collection('employees')
        .doc(phone)
        .get();
    
    if (!empSnap.exists) return;

    final empData = empSnap.data()!;
    final geoId = empData['geofence_id'] as String?;
    if (geoId == null || geoId.isEmpty) return;

    // Get geofence data
    final geoSnap = await FirebaseFirestore.instance
        .collection('geofences')
        .doc(geoId)
        .get();
    
    if (!geoSnap.exists) return;

    final geoData = geoSnap.data()!;
    final geopoint = geoData['geopoint'] as GeoPoint;
    final radius = (geoData['radius'] as num).toDouble();

    // Get current location
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Check if inside geofence
    final distance = distanceInMeters(
      geopoint.latitude, 
      geopoint.longitude, 
      pos.latitude, 
      pos.longitude
    );
    final inside = distance <= radius;

    // Process attendance
    await _processAttendance(phone, geoId, pos, inside);

  } catch (e) {
    print('Geofence check error: $e');
  }
}

Future<void> _processAttendance(
  String phone, 
  String geoId, 
  Position pos, 
  bool inside
) async {
  final dateStr = todayDateString();
  final attRef = FirebaseFirestore.instance
      .collection('employees')
      .doc(phone)
      .collection('attendance')
      .doc(dateStr);

  final attSnap = await attRef.get();
  final attData = attSnap.exists ? attSnap.data()! : <String, dynamic>{};

  if (inside) {
    // Employee entered geofence
    if (attData['check_in'] == null) {
      // EXACT match to your database structure
      await attRef.set({
        'check_in': FieldValue.serverTimestamp(),
        'geofence_id': geoId,
        'date': dateStr,  // EXACT field from your DB
        'status': 'Present',
      }, SetOptions(merge: true));

      // EXACT log structure from your database
      await attRef.collection('logs').add({
        'event': 'entered',
        'time': FieldValue.serverTimestamp(),
        'geopoint': GeoPoint(pos.latitude, pos.longitude), // EXACT GeoPoint format
      });
    }
  } else {
    // Employee exited geofence
    if (attData['check_in'] != null && attData['check_out'] == null) {
      await attRef.set({
        'check_out': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // EXACT log structure from your database
      await attRef.collection('logs').add({
        'event': 'exited',
        'time': FieldValue.serverTimestamp(),
        'geopoint': GeoPoint(pos.latitude, pos.longitude), // EXACT GeoPoint format
      });

      // Calculate total hours immediately
      await _calculateTotalHours(attRef);
    }
  }
}

Future<void> _calculateTotalHours(DocumentReference attRef) async {
  try {
    final attSnap = await attRef.get();
    if (!attSnap.exists) return;
    
    final attData = attSnap.data() as Map<String, dynamic>;
    final checkIn = attData['check_in'] as Timestamp?;
    final checkOut = attData['check_out'] as Timestamp?;
    
    if (checkIn != null && checkOut != null) {
      final duration = checkOut.toDate().difference(checkIn.toDate());
      final totalHoursDecimal = durationToHours(duration);
      
      String status;
      if (totalHoursDecimal >= 7) {
        status = 'Present';
      } else if (totalHoursDecimal >= 3) {
        status = 'Half-Day';
      } else {
        status = 'Absent';
      }
      
      // EXACT match to your DB: integer total_hours (8, not 8.0)
      await attRef.update({
        'total_hours': totalHoursDecimal.round(), // INTEGER like your database
        'status': status,
      });
      
      print('Calculated total hours: ${totalHoursDecimal.round()}, Status: $status');
    }
  } catch (e) {
    print('Error calculating total hours: $e');
  }
}





/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils.dart';
import '../constants.dart';

/// Background geofence check logic
/// This runs periodically via WorkManager to check employee location
Future<void> runGeofenceCheck() async {
  try {
    print("🔄 Running background geofence check...");
    
    // Get stored employee phone from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('employee_phone');
    
    if (phone == null || phone.isEmpty) {
      print("❌ No employee phone found in SharedPreferences");
      return;
    }

    // Fetch employee data from Firestore
    final empDoc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.employees)
        .doc(phone)
        .get();
    
    if (!empDoc.exists) {
      print("❌ Employee document not found for phone: $phone");
      return;
    }

    final empData = empDoc.data()!;
    final geofenceId = empData[FirestoreFields.geofenceId] as String?;
    
    if (geofenceId == null || geofenceId.isEmpty) {
      print("❌ No geofence_id assigned to employee: $phone");
      return;
    }

    // Fetch geofence data
    final geoDoc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.geofences)
        .doc(geofenceId)
        .get();
    
    if (!geoDoc.exists) {
      print("❌ Geofence document not found: $geofenceId");
      return;
    }

    final geoData = geoDoc.data()!;
    final geoPoint = geoData[FirestoreFields.geofencePoint] as GeoPoint;
    final radius = (geoData[FirestoreFields.radius] as num).toDouble();

    // Get current location with timeout and error handling
    Position currentPosition;
    try {
      // Check location permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("❌ Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("❌ Location permission permanently denied");
        return;
      }

      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add timeout
      );
    } catch (e) {
      print("❌ Failed to get current location: $e");
      return;
    }

    // Calculate distance and check if inside geofence
    final distance = distanceInMeters(
      geoPoint.latitude,
      geoPoint.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );
    
    final isInsideGeofence = distance <= radius;
    print("📍 Distance: ${distance.toStringAsFixed(2)}m, Inside: $isInsideGeofence");

    // Get today's date string (YYYY-MM-DD format)
    final dateStr = todayDateString();
    final attendanceRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.employees)
        .doc(phone)
        .collection(FirestoreCollections.attendance)
        .doc(dateStr);

    final attendanceDoc = await attendanceRef.get();
    final attendanceData = attendanceDoc.exists ? attendanceDoc.data()! : <String, dynamic>{};

    if (isInsideGeofence) {
      // Employee entered the geofence
      if (attendanceData[FirestoreFields.checkIn] == null) {
        print("✅ Employee entered geofence - recording check-in");
        
        // Set check-in timestamp
        await attendanceRef.set({
          FirestoreFields.checkIn: FieldValue.serverTimestamp(),
          FirestoreFields.attendanceGeofenceId: geofenceId,
        }, SetOptions(merge: true));

        // Log the entry event
        await attendanceRef.collection(FirestoreCollections.logs).add({
          FirestoreFields.event: LogEvents.entered,
          FirestoreFields.time: FieldValue.serverTimestamp(),
          FirestoreFields.geopoint: GeoPoint(
            currentPosition.latitude,
            currentPosition.longitude,
          ),
        });
        
        print("📝 Check-in recorded successfully");
      } else {
        print("ℹ️ Already checked in today");
      }
    } else {
      // Employee is outside the geofence
      final hasCheckedIn = attendanceData[FirestoreFields.checkIn] != null;
      final hasCheckedOut = attendanceData[FirestoreFields.checkOut] != null;
      
      if (hasCheckedIn && !hasCheckedOut) {
        print("✅ Employee exited geofence - recording check-out");
        
        // Set check-out timestamp
        await attendanceRef.set({
          FirestoreFields.checkOut: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Log the exit event
        await attendanceRef.collection(FirestoreCollections.logs).add({
          FirestoreFields.event: LogEvents.exited,
          FirestoreFields.time: FieldValue.serverTimestamp(),
          FirestoreFields.geopoint: GeoPoint(
            currentPosition.latitude,
            currentPosition.longitude,
          ),
        });
        
        print("📝 Check-out recorded successfully");
      } else if (!hasCheckedIn) {
        print("ℹ️ Employee outside geofence, no check-in today");
      } else {
        print("ℹ️ Already checked out today");
      }
    }

  } catch (e, stackTrace) {
    print("❌ Error in geofence check: $e");
    print("Stack trace: $stackTrace");
    
    // Optional: Log error to Firestore for debugging
    try {
      await FirebaseFirestore.instance.collection('debug_logs').add({
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'function': 'runGeofenceCheck',
      });
    } catch (logError) {
      print("Failed to log error: $logError");
    }
  }
}*/