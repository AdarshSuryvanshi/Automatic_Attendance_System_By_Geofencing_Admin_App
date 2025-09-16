import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class DummySeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDummyData() async {
    try {
      // 🔹 Step 1: Create Geofence
      final String geofenceId = "cKDAla2JhwvKNYxy660r";
      final geofenceRef =
          _firestore.collection(FirestoreCollections.geofences).doc(geofenceId);

      await geofenceRef.set({
        FirestoreFields.geofencePoint: const GeoPoint(18.70, 70.33),
        FirestoreFields.radius: 200,
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      });

      // 🔹 Step 2: Create Employee
      final String phone = "+917020670484"; // doc_id = phone
      final employeeRef =
          _firestore.collection(FirestoreCollections.employees).doc(phone);

      await employeeRef.set({
        FirestoreFields.name: "Adarsh",
        FirestoreFields.phone: phone,
        FirestoreFields.geofenceId: geofenceId
      });

      // 🔹 Step 3: Create Attendance for today
      final String todayDate = "2025-09-06";
      final attendanceRef =
          employeeRef.collection(FirestoreCollections.attendance).doc(todayDate);

      await attendanceRef.set({
        FirestoreFields.checkIn: DateTime.parse("2025-09-06T09:15:00Z"),
        FirestoreFields.checkOut: DateTime.parse("2025-09-06T17:05:00Z"),
        FirestoreFields.totalHours: 7.8,
        FirestoreFields.attendanceStatus: AttendanceStatus.present,
        FirestoreFields.attendanceGeofenceId: geofenceId,
      });

      // 🔹 Step 4: Add logs inside attendance
      final logsRef = attendanceRef.collection(FirestoreCollections.logs);

      await logsRef.add({
        FirestoreFields.event: LogEvents.entered,
        FirestoreFields.time: DateTime.parse("2025-09-06T09:15:00Z"),
        FirestoreFields.geopoint: const GeoPoint(18.70, 70.33),
      });

      await logsRef.add({
        FirestoreFields.event: LogEvents.exited,
        FirestoreFields.time: DateTime.parse("2025-09-06T17:05:00Z"),
        FirestoreFields.geopoint: const GeoPoint(18.71, 70.34),
      });

      print("✅ Dummy data seeded successfully!");
    } catch (e) {
      print("❌ Error seeding dummy data: $e");
    }
  }
}
