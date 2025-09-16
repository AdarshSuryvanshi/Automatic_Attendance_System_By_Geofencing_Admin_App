import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as Math; // Moved to top
/// Calculate distance between two latitude/longitude points in meters
double distanceInMeters(
    double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // meters

  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);

  final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(_degreesToRadians(lat1)) *
          Math.cos(_degreesToRadians(lat2)) *
          Math.sin(dLon / 2) *
          Math.sin(dLon / 2);

  final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * Math.pi / 180;
}

/// Returns today's date as a string in yyyy-MM-dd format
String todayDateString() {
  final now = DateTime.now();
  return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
}

/// Converts a Duration object to decimal hours (e.g., 1 hour 30 mins => 1.5)
double durationToHours(Duration duration) {
  return duration.inMinutes / 60.0;
}

/// Utility functions for attendance management
class AttendanceUtils {
  /// Returns today's date string in YYYY-MM-DD format
  static String todayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Returns date string in YYYY-MM-DD format for given DateTime
  static String dateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formats time from Timestamp to HH:mm format
  static String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '--';
    final time = timestamp.toDate();
    return DateFormat('HH:mm').format(time);
  }

  /// Formats date for display (dd MMM yyyy)
  static String formatDateForDisplay(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Calculates total working hours between check-in and check-out
  static int calculateTotalHours(Timestamp? checkIn, Timestamp? checkOut) {
    if (checkIn == null || checkOut == null) return 0;
    final duration = checkOut.toDate().difference(checkIn.toDate());
    return duration.inHours;
  }

  /// Calculates total working hours with minutes precision
  static double calculateTotalHoursWithMinutes(Timestamp? checkIn,
      Timestamp? checkOut) {
    if (checkIn == null || checkOut == null) return 0.0;
    final duration = checkOut.toDate().difference(checkIn.toDate());
    return duration.inMinutes / 60.0;
  }

  /// Determines attendance status based on check-in/check-out times
  static String determineAttendanceStatus(Timestamp? checkIn,
      Timestamp? checkOut, {DateTime? targetDate}) {
    final now = DateTime.now();
    final target = targetDate ?? now;

    // If it's a future date, return empty
    if (target.isAfter(DateTime(now.year, now.month, now.day))) {
      return '';
    }

    // If no check-in, mark as absent
    if (checkIn == null) {
      return 'Absent';
    }

    // If check-in exists but no check-out and it's today, still working
    if (checkOut == null && _isToday(target)) {
      return 'Working';
    }

    // If check-in exists, mark as present
    return 'Present';
  }

  /// Checks if given date is today
  static bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// Gets color for attendance status
  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return '#28A745'; // Green
      case 'absent':
        return '#DC3545'; // Red
      case 'late':
        return '#FFC107'; // Yellow
      case 'working':
        return '#17A2B8'; // Blue
      default:
        return '#6C757D'; // Gray
    }
  }

  /// Validates phone number format
  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Add country code if not present (assuming Indian numbers)
    if (digitsOnly.length == 10) {
      digitsOnly = '+91$digitsOnly';
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      digitsOnly = '+$digitsOnly';
    } else if (!digitsOnly.startsWith('+')) {
      digitsOnly = '+$digitsOnly';
    }

    return digitsOnly;
  }

  /// Creates attendance record for employee
  static Future<void> createAttendanceRecord({
    required String employeePhone,
    required String geofenceId,
    required DateTime date,
    Timestamp? checkIn,
    Timestamp? checkOut,
    String? status,
    int? totalHours,
  }) async {
    final dateStr = dateString(date);

    final data = <String, dynamic>{
      'geofence_id': geofenceId,
      'date': dateStr,
    };

    if (checkIn != null) data['check_in'] = checkIn;
    if (checkOut != null) data['check_out'] = checkOut;
    if (status != null) data['status'] = status;
    if (totalHours != null) data['total_hours'] = totalHours;

    await FirebaseFirestore.instance
        .collection('employees')
        .doc(employeePhone)
        .collection('attendance')
        .doc(dateStr)
        .set(data, SetOptions(merge: true));
  }

  /// Updates employee check-in time
  static Future<void> updateCheckIn({
    required String employeePhone,
    required String geofenceId,
    required DateTime checkInTime,
  }) async {
    final dateStr = todayDateString();

    await createAttendanceRecord(
      employeePhone: employeePhone,
      geofenceId: geofenceId,
      date: DateTime.now(),
      checkIn: Timestamp.fromDate(checkInTime),
      status: 'Present',
    );

    // Also create a log entry
    await _createLogEntry(employeePhone, 'entered', checkInTime);
  }

  /// Updates employee check-out time
  static Future<void> updateCheckOut({
    required String employeePhone,
    required String geofenceId,
    required DateTime checkOutTime,
  }) async {
    final dateStr = todayDateString();

    // Get existing attendance record to calculate total hours
    final attendanceDoc = await FirebaseFirestore.instance
        .collection('employees')
        .doc(employeePhone)
        .collection('attendance')
        .doc(dateStr)
        .get();

    if (attendanceDoc.exists) {
      final data = attendanceDoc.data()!;
      final checkIn = data['check_in'] as Timestamp?;

      if (checkIn != null) {
        final totalHours = calculateTotalHours(
            checkIn, Timestamp.fromDate(checkOutTime));

        await createAttendanceRecord(
          employeePhone: employeePhone,
          geofenceId: geofenceId,
          date: DateTime.now(),
          checkOut: Timestamp.fromDate(checkOutTime),
          totalHours: totalHours,
          status: 'Present',
        );
      }
    }

    // Also create a log entry
    await _createLogEntry(employeePhone, 'exited', checkOutTime);
  }

  /// Creates a log entry for geofence events
  static Future<void> _createLogEntry(String employeePhone, String event,
      DateTime time) async {
    final dateStr = todayDateString();

    await FirebaseFirestore.instance
        .collection('employees')
        .doc(employeePhone)
        .collection('attendance')
        .doc(dateStr)
        .collection('logs')
        .add({
      'event': event,
      'time': Timestamp.fromDate(time),
      'geopoint': null, // Will be filled by geofence service
    });
  }

  /// Gets attendance statistics for a specific date and geofence
  static Future<Map<String, int>> getAttendanceStats({
    required DateTime date,
    String? geofenceId,
  }) async {
    final dateStr = dateString(date);

    Query query = FirebaseFirestore.instance
        .collectionGroup('attendance')
        .where('date', isEqualTo: dateStr);

    if (geofenceId != null && geofenceId != 'all') {
      query = query.where('geofence_id', isEqualTo: geofenceId);
    }

    final snapshot = await query.get();

    int totalEmployees = 0;
    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;

    for (var doc in snapshot.docs) {
      totalEmployees++;
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'Absent';

      switch (status.toLowerCase()) {
        case 'present':
          presentCount++;
          break;
        case 'late':
          lateCount++;
          break;
        default:
          absentCount++;
      }
    }

    return {
      'total': totalEmployees,
      'present': presentCount,
      'absent': absentCount,
      'late': lateCount,
    };
  }

  /// Checks if employee is currently inside geofence
  /// Checks if employee is currently inside geofence
  static Future<bool> isEmployeeInGeofence({
    required String employeePhone,
    required String geofenceId,
  }) async {
    final today = todayDateString();

    final attendanceDoc = await FirebaseFirestore.instance
        .collection('employees')
        .doc(employeePhone)
        .collection('attendance')
        .doc(today)
        .get();

    if (!attendanceDoc.exists) {
      return false; // 🔹 Safely return false if no record
    }

    final data = attendanceDoc.data();
    if (data == null) {
      return false; // 🔹 Again, return false if somehow data is null
    }

    final checkIn = data['check_in'] as Timestamp?;
    final checkOut = data['check_out'] as Timestamp?;

    // ✅ Ensure return value on all paths
    return checkIn != null && checkOut == null;
  }


}
/*
import 'dart:math';
import 'package:intl/intl.dart';

double distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000; // meters
  final dLat = (lat2 - lat1) * (pi / 180);
  final dLon = (lon2 - lon1) * (pi / 180);
  final a = sin(dLat/2) * sin(dLat/2) +
      cos(lat1 * pi/180) * cos(lat2 * pi/180) *
          sin(dLon/2) * sin(dLon/2);
  final c = 2 * atan2(sqrt(a), sqrt(1-a));
  return R * c;
}

double durationToHours(Duration duration) {
  return duration.inMilliseconds / 3600000.0;
}


String todayDateString() {
  final now = DateTime.now().toLocal();
  return DateFormat('yyyy-MM-dd').format(now);
}
*/