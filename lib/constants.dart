/// Firestore collection names - EXACT match to your database
class FirestoreCollections {
  static const String employees = "employees";   
  static const String attendance = "attendance"; 
  static const String logs = "logs";             
  static const String geofences = "geofences";   
}

/// Firestore field names - ONLY fields that exist in your database
class FirestoreFields {
  // Employee fields - EXACT match to your DB schema
  static const String name = "name";
  static const String phone = "phone";
  static const String geofenceId = "geofence_id";

  // Attendance fields - EXACT match to your DB schema
  static const String checkIn = "check_in";
  static const String checkOut = "check_out";
  static const String totalHours = "total_hours";  // Integer in your DB
  static const String attendanceStatus = "status";
  static const String attendanceGeofenceId = "geofence_id";
  static const String date = "date"; // ADDED - exists in your DB

  // Log fields - EXACT match to your DB schema
  static const String event = "event";
  static const String time = "time";
  static const String geopoint = "geopoint"; // GeoPoint in your DB

  // Geofence fields - EXACT match to your DB schema
  static const String geofencePoint = "geopoint";
  static const String radius = "radius";
  static const String createdAt = "created_at";
}

/// Attendance status - match your database values
class AttendanceStatus {
  static const String present = "Present";
  static const String absent = "Absent";
  static const String halfDay = "Half-Day";
}

/// Log events - match your database values
class LogEvents {
  static const String entered = "entered";
  static const String exited = "exited";
}




/*/// Firestore collection names
class FirestoreCollections {
  static const String employees = "employees";   // Root collection (doc_id = phone number)
  static const String attendance = "attendance"; // Subcollection inside employee
  static const String logs = "logs";             // Subcollection inside attendance
  static const String geofences = "geofences";   // Root collection for geofences
}

/// Firestore field names
class FirestoreFields {
  // Employee fields
  static const String name = "name";
  static const String phone = "phone";
  static const String geofenceId = "geofence_id";


  // Attendance fields
  static const String checkIn = "check_in";     // Firestore Timestamp
  static const String checkOut = "check_out";   // Firestore Timestamp
  static const String totalHours = "total_hours"; // double/number
  static const String attendanceStatus = "status"; // "Present", "Absent", etc.
  static const String attendanceGeofenceId = "geofence_id"; // link to geofence
        // optional field, ISO date string

  // Log fields
  static const String event = "event"; // "entered" | "exited"
  static const String time = "time";   // Firestore Timestamp
  static const String geopoint = "geopoint"; // Firestore GeoPoint {lat, lng}

  // Geofence fields
  static const String geofencePoint = "geopoint";  // Firestore GeoPoint {lat, lng}
  static const String radius = "radius";          // in meters
  static const String createdAt = "created_at";   // Firestore Timestamp
}


/// Attendance status
class AttendanceStatus {
  static const String present = "Present";
  static const String absent = "Absent";
  static const String halfDay = "Half-Day";
}

/// Log events
class LogEvents {
  static const String entered = "entered";
  static const String exited = "exited";
}
*/