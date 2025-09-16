import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'geofence_preview_page.dart';

class GeofenceSetupPage extends StatefulWidget {
  @override
  _GeofenceSetupPageState createState() => _GeofenceSetupPageState();
}

class _GeofenceSetupPageState extends State<GeofenceSetupPage> {
  final TextEditingController locationNameController = TextEditingController();
  final TextEditingController radiusController = TextEditingController(text: '200');

  // New: Lat/Lng input controllers
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  GoogleMapController? mapController;
  LatLng? selectedLocation;
  String selectedAddress = "Tap on map to select location";
  bool isLoading = false;

  // Default location (Mumbai)
  static const LatLng defaultLocation = LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          selectedLocation = defaultLocation;
          latitudeController.text = defaultLocation.latitude.toStringAsFixed(6);
          longitudeController.text = defaultLocation.longitude.toStringAsFixed(6);
          isLoading = false;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            selectedLocation = defaultLocation;
            latitudeController.text = defaultLocation.latitude.toStringAsFixed(6);
            longitudeController.text = defaultLocation.longitude.toStringAsFixed(6);
            isLoading = false;
          });
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
        latitudeController.text = position.latitude.toStringAsFixed(6);
        longitudeController.text = position.longitude.toStringAsFixed(6);
      });
      _getAddressFromLatLng(selectedLocation!);
    } catch (e) {
      setState(() {
        selectedLocation = defaultLocation;
        latitudeController.text = defaultLocation.latitude.toStringAsFixed(6);
        longitudeController.text = defaultLocation.longitude.toStringAsFixed(6);
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          selectedAddress = "${place.street}, ${place.locality}, ${place.administrativeArea}";
          if (locationNameController.text.isEmpty) {
            locationNameController.text = place.locality ?? place.subLocality ?? "Location";
          }
        });
      } else {
        setState(() {
          selectedAddress = "Address not available";
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress = "Address not available";
      });
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      selectedLocation = position;
      selectedAddress = "Loading address...";
      // keep lat/lng inputs synced with map selection
      latitudeController.text = position.latitude.toStringAsFixed(6);
      longitudeController.text = position.longitude.toStringAsFixed(6);
    });
    _getAddressFromLatLng(position);
  }

  // validation helpers for coordinate ranges
  bool _isValidLat(double? v) => v != null && v >= -90 && v <= 90; // standard lat range [3][1]
  bool _isValidLng(double? v) => v != null && v >= -180 && v <= 180; // standard lng range [3][1]

  // apply user-entered coordinates to map and address
  void _applyLatLngFromInputs({bool animate = true}) {
    final lat = double.tryParse(latitudeController.text.trim());
    final lng = double.tryParse(longitudeController.text.trim());
    if (!_isValidLat(lat) || !_isValidLng(lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid latitude (−90..90) and longitude (−180..180)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final pos = LatLng(lat!, lng!);
    setState(() {
      selectedLocation = pos;
      selectedAddress = "Loading address...";
    });
    _getAddressFromLatLng(pos);

    if (mapController != null) {
      final update = CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 16));
      if (animate) {
        mapController!.animateCamera(update);
      } else {
        mapController!.moveCamera(update);
      }
    }
  }

  void _onSetUp() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final locationName = locationNameController.text.trim();
    final radius = double.tryParse(radiusController.text.trim());
    if (locationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a location name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (radius == null || radius <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid radius'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeofencePreviewPage(
          locationName: locationName,
          locationAddress: selectedAddress,
          lat: selectedLocation!.latitude,
          lng: selectedLocation!.longitude,
          radius: radius,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Setup Geofence',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F3460),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map Container
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: isLoading
                    ? Container(
                  color: const Color(0xFF16213E),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
                    ),
                  ),
                )
                    : selectedLocation != null
                    ? Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: selectedLocation!,
                        zoom: 16,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                      },
                      onTap: _onMapTap,
                      markers: selectedLocation != null
                          ? {
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: selectedLocation!,
                          draggable: true,
                          onDragEnd: _onMapTap,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      }
                          : {},
                      circles: selectedLocation != null
                          ? {
                        Circle(
                          circleId: const CircleId('radius'),
                          center: selectedLocation!,
                          radius: double.tryParse(radiusController.text) ?? 200,
                          fillColor: const Color(0xFFE94560).withOpacity(0.2),
                          strokeColor: const Color(0xFFE94560),
                          strokeWidth: 2,
                        ),
                      }
                          : {},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                    // Map overlay instructions
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tap on the map to select geofence location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
                    : Container(
                  color: const Color(0xFF16213E),
                  child: const Center(
                    child: Text('Loading Map...', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
          // Form Container
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected Location Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Location',
                            style: TextStyle(
                              color: Color(0xFFE94560),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          if (selectedLocation != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location Name Field
                    const Text(
                      'Location Name',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: locationNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Main Office, Factory 1',
                          hintStyle: TextStyle(color: Colors.white60),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          prefixIcon: Icon(Icons.location_city, color: Color(0xFFE94560)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Exact Coordinates Fields
                    const Text(
                      'Exact Coordinates',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: TextField(
                              controller: latitudeController,
                              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                              ],
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) {
                                final lat = double.tryParse(latitudeController.text.trim());
                                final lng = double.tryParse(longitudeController.text.trim());
                                if (_isValidLat(lat) && _isValidLng(lng)) {
                                  _applyLatLngFromInputs(animate: false);
                                }
                              },
                              decoration: const InputDecoration(
                                hintText: 'Latitude (−90..90)',
                                hintStyle: TextStyle(color: Colors.white60),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                prefixIcon: Icon(Icons.explore, color: Color(0xFFE94560)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: TextField(
                              controller: longitudeController,
                              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                              ],
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) {
                                final lat = double.tryParse(latitudeController.text.trim());
                                final lng = double.tryParse(longitudeController.text.trim());
                                if (_isValidLat(lat) && _isValidLng(lng)) {
                                  _applyLatLngFromInputs(animate: false);
                                }
                              },
                              decoration: const InputDecoration(
                                hintText: 'Longitude (−180..180)',
                                hintStyle: TextStyle(color: Colors.white60),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                prefixIcon: Icon(Icons.public, color: Color(0xFFE94560)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _applyLatLngFromInputs,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE94560)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use Lat/Lng'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Radius Field
                    const Text(
                      'Geofence Radius (meters)',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: radiusController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {}); // refresh circle
                        },
                        decoration: const InputDecoration(
                          hintText: 'e.g. 200',
                          hintStyle: TextStyle(color: Colors.white60),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          prefixIcon: Icon(Icons.radar, color: Color(0xFFE94560)),
                          suffixText: 'meters',
                          suffixStyle: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Setup Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE94560), Color(0xFFD63384)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE94560).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: _onSetUp,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.preview, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Preview Geofence',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    locationNameController.dispose();
    radiusController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }
}
