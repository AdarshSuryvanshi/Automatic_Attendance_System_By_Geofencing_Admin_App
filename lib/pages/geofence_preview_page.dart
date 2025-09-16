import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geofence_attendance/pages/homepage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofencePreviewPage extends StatelessWidget {
  final String locationName;
  final String locationAddress;
  final double lat;
  final double lng;
  final double radius;

  const GeofencePreviewPage({
    super.key,
    required this.locationName,
    required this.locationAddress,
    required this.lat,
    required this.lng,
    required this.radius,
  });

  Future<String> _saveGeofence() async {
    final docRef = await FirebaseFirestore.instance
        .collection('geofences')
        .add({
      'geopoint': GeoPoint(lat, lng),
      'radius': radius,
      'location_name': locationName,
      'location_add': locationAddress,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Widget build(BuildContext context) {
    final CameraPosition initial = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 17,
    );

    final Circle circle = Circle(
      circleId: const CircleId('geofence'),
      center: LatLng(lat, lng),
      radius: radius,
      fillColor: const Color(0xFFE94560).withOpacity(0.15),
      strokeColor: const Color(0xFFE94560),
      strokeWidth: 3,
    );

    final Marker marker = Marker(
      markerId: const MarkerId('center'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: locationName,
        snippet: locationAddress,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Preview Geofence',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F3460),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Google Maps
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: GoogleMap(
                initialCameraPosition: initial,
                markers: {marker},
                circles: {circle},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),

          // Top Info Card
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE94560),
                                const Color(0xFFD63384),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Geofence Configuration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Location Name
                    _buildInfoRow(
                      icon: Icons.business,
                      label: 'Location Name',
                      value: locationName,
                    ),

                    const SizedBox(height: 12),

                    // Address
                    _buildInfoRow(
                      icon: Icons.location_city,
                      label: 'Address',
                      value: locationAddress,
                    ),

                    const SizedBox(height: 12),

                    // Coordinates
                    _buildInfoRow(
                      icon: Icons.my_location,
                      label: 'Coordinates',
                      value: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                    ),

                    const SizedBox(height: 12),

                    // Radius
                    _buildInfoRow(
                      icon: Icons.radar,
                      label: 'Detection Radius',
                      value: '${radius.toInt()} meters',
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94560).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE94560).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFFE94560),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Employees will automatically check-in when entering this area',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Buttons
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Confirm Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF28A745),
                        const Color(0xFF20C997),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF28A745).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () async {
                        try {
                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Container(
                              color: Colors.black54,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF1A1A2E),
                                        const Color(0xFF16213E),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          const Color(0xFFE94560),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Saving Geofence...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          // Save geofence
                          await _saveGeofence();

                          Navigator.of(context).pop(); // Hide loading

                          // Navigate back to home
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const HomeScreenWidget(),
                            ),
                                (route) => false,
                          );

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Geofence "$locationName" saved successfully!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF28A745),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } catch (e) {
                          Navigator.of(context).pop(); // Hide loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Error saving geofence: $e',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Confirm & Save Geofence',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Back Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Go Back & Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFE94560),
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF1A1A2E).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geofence_attendance/pages/Homepage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'attendance_dashboard_page.dart';

class GeofencePreviewPage extends StatelessWidget {

  final double lat;
  final double lng;
  final double radius;

  const GeofencePreviewPage({
    super.key,

    required this.lat,
    required this.lng,
    required this.radius,
  });

  Future<String> _saveGeofence() async {
    final docRef = await FirebaseFirestore.instance
        .collection('geofences')
        .add({
         // NEW
      'geopoint': GeoPoint(lat, lng),
      'radius': radius,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Widget build(BuildContext context) {
    final CameraPosition initial = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 17,
    );

    final Circle circle = Circle(
      circleId: const CircleId('geofence'),
      center: LatLng(lat, lng),
      radius: radius,
      fillColor: Colors.blue.withOpacity(0.15),
      strokeColor: Colors.blue,
      strokeWidth: 2,
    );

    final Marker marker = Marker(
      markerId: const MarkerId('center'),
      position: LatLng(lat, lng),
      infoWindow: const InfoWindow(title: "Geofence Center"),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Geofence'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // ✅ Google Maps implementation
          GoogleMap(
            initialCameraPosition: initial,
            markers: {marker},
            circles: {circle},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),

          // Info card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Geofence Configuration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text('Latitude: ${lat.toStringAsFixed(6)}'),
                    Text('Longitude: ${lng.toStringAsFixed(6)}'),
                    Text('Radius: ${radius.toInt()} meters'),
                    const SizedBox(height: 4),
                    Text(
                      'Employees will check in when entering this area',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Confirm button (inside GeofencePreviewPage)
              onPressed: () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Save geofence
                  final geoId = await _saveGeofence();

                  Navigator.of(context).pop(); // hide loading

                  // Pop back to Home (remove all previous pages and go Home)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreenWidget()),
                        (route) => false,
                  );

                  // Success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Geofence saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving geofence: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },

              child: const Text(
                'Confirm & Save Geofence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/