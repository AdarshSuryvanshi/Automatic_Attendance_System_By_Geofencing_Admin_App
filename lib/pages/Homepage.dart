import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geofence_attendance/pages/chatbot.dart';
import 'package:geofence_attendance/pages/geofence_setup_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geofence_attendance/pages/employee_list_page.dart';
import 'package:geofence_attendance/pages/attendance_dashboard_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geofence_attendance/pages/orglogo.dart';
import 'package:geofence_attendance/pages/statistics.dart';
import 'package:geofence_attendance/pages/chatbot.dart';
String? organizationLogoBase64; // holds Base64 string

Uint8List? organizationLogoBytes; // for web display


class HomeScreenWidget extends StatefulWidget {
  const HomeScreenWidget({super.key});

  static String routeName = 'HomeScreen';
  static String routePath = '/homeScreen';

  @override
  State<HomeScreenWidget> createState() => _HomeScreenWidgetState();
}

class _HomeScreenWidgetState extends State<HomeScreenWidget>
    with TickerProviderStateMixin {
  late TabController _tabBarController;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Organization setup variables - Fixed null safety
  String organizationName = '';
  String? organizationLogoPath;
  bool isOrganizationSetup = false;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _orgNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabBarController = TabController(
      vsync: this,
      length: 4,
      initialIndex: 0,
    )..addListener(() => setState(() {}));

    _loadOrganizationInfo();
  }

  @override
  void dispose() {
    _tabBarController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  // Load organization information from SharedPreferences
  Future<void> _loadOrganizationInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        organizationName = prefs.getString('organization_name') ?? '';
        organizationLogoPath = prefs.getString('organization_logo');
        isOrganizationSetup = organizationName.isNotEmpty;
      });
    } catch (e) {
      print('Error loading organization info: $e');
      // Set default values in case of error
      setState(() {
        organizationName = '';
        organizationLogoPath = null;
        isOrganizationSetup = false;
      });
    }
  }

  // Save organization information to SharedPreferences
  Future<void> _saveOrganizationInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('organization_name', organizationName);
      if (organizationLogoPath != null) {
        await prefs.setString('organization_logo', organizationLogoPath!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save organization info: $e'),
            backgroundColor: const Color(0xFFE94560),
          ),
        );
      }
    }
  }
  Future<String> _networkImageToBase64(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      return base64Encode(res.bodyBytes);
    }
    throw Exception('Failed to fetch default image (${res.statusCode})');
  }

  // Pick image from gallery
  Future<void> _pickImageToBase64() async {
    const defaultUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRXh1S4HYltl1fE4orWANITBLYK-C7YmXXTPjxR48KIMXvfcRZU7c3OeNJW6m77etFrYxs&usqp=CAU';

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        // Nothing picked → use default URL as Base64
        final b64 = await _networkImageToBase64(defaultUrl);
        setState(() {
          organizationLogoBase64 = b64;
        });
        return;
      }

      // Works on web and mobile: read bytes, then base64-encode
      final bytes = await image.readAsBytes(); // async variant is web-safe
      final b64 = base64Encode(bytes);

      setState(() {
        organizationLogoBase64 = b64;
      });
    } catch (e) {
      // On any error, fall back to default
      try {
        final b64 = await _networkImageToBase64(defaultUrl);
        if (mounted) {
          setState(() {
            organizationLogoBase64 = b64;
          });
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick/convert image: $e'),
            backgroundColor: const Color(0xFFE94560),
          ),
        );
      }
    }
  }



  // Show organization setup dialog - Fixed null safety
  void _showOrganizationSetup() {
    _orgNameController.text = organizationName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Setup Organization',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo picker
                  GestureDetector(
                    onTap: () async {
                      await _pickImageToBase64();
                      setDialogState(() {});
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE94560),
                            const Color(0xFFD63384),
                          ],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: organizationLogoBase64 != null
                          ? OrgLogo(
                        radius: 50,
                        base64Image: organizationLogoBase64, // Base64 string (web-safe)
                        filePath: organizationLogoPath,      // File path (mobile/desktop)
                        placeholder: const Icon(Icons.business, size: 24, color: Colors.white),
                      )

                      : Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Tap to add organization logo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Organization name input - Fixed null safety
                  TextField(
                    controller: _orgNameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Organization Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFE94560)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        organizationName = value.trim(); // Update local state
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: organizationName.isNotEmpty ? () async {
                    await _saveOrganizationInfo();
                    setState(() {
                      isOrganizationSetup = true;
                    });
                    Navigator.of(context).pop();
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: organizationName.isNotEmpty ? LinearGradient(
                        colors: [
                          const Color(0xFFE94560),
                          const Color(0xFFD63384),
                        ],
                      ) : null,
                      color: organizationName.isEmpty ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget buildLogoFromBase64(double radius) {
    if (organizationLogoBase64 == null) {
      return const Icon(Icons.add_a_photo, color: Colors.white);
    }
    final bytes = base64Decode(organizationLogoBase64!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.memory(bytes, fit: BoxFit.cover),
    );
  }

  // Delete geofence function
  Future<void> _deleteGeofence(String geofenceId, String locationName) async {
    // Show confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Location',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "$locationName"? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('geofences')
            .doc(geofenceId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location "$locationName" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete location: $e'),
              backgroundColor: const Color(0xFFE94560),
            ),
          );
        }
      }
    }
  }

  // Helper method to build setting items
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(enabled ? 0.05 : 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(enabled ? 0.1 : 0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white70 : Colors.white30,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.white : Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? Colors.white60 : Colors.white30,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: enabled ? Colors.white : Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show organization setup if not completed
    if (!isOrganizationSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showOrganizationSetup();
        }
      });
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabBarController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // ---------------- Tab 1: Home ----------------
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1A1A2E),
                            const Color(0xFF16213E),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Enhanced Header with organization info - Fixed null safety
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0F3460),
                                  const Color(0xFF16213E),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              organizationName.isNotEmpty
                                                  ? organizationName
                                                  : 'Organization Name',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _showOrganizationSetup,
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Smart Attendance System',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFE94560),
                                        const Color(0xFFD63384),
                                      ],
                                    ),
                                  ),
                                  child: OrgLogo(
                                    radius: 50,
                                    base64Image: organizationLogoBase64, // Base64 string (web-safe)
                                    filePath: organizationLogoPath,      // File path (mobile/desktop)
                                    placeholder: const Icon(Icons.business, size: 24, color: Colors.white),
                                  ),

                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Title + Add button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Locations',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFE94560),
                                        const Color(0xFFD63384),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
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
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GeofenceSetupPage(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_location,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Add Location',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
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

                          const SizedBox(height: 20),

                          // Enhanced Firestore list of geofences with delete functionality
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('geofences')
                                  .orderBy('created_at', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFFE94560),
                                      ),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_off,
                                          size: 80,
                                          color: Colors.white30,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "No geofences added yet",
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Tap 'Add Location' to create your first geofence",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final geofences = snapshot.data!.docs;

                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: geofences.length,
                                  itemBuilder: (context, index) {
                                    final data = geofences[index].data() as Map<String, dynamic>;
                                    final geo = data['geopoint'] as GeoPoint?;
                                    final radius = data['radius'] ?? 0;
                                    final locationName = data['location_name'] ?? "Unknown Location";
                                    final locationAdd = data['location_add'] ?? "Address not available";
                                    final geofenceId = geofences[index].id;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.1),
                                            Colors.white.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EmployeeDetailPage(
                                                  geofenceId: geofenceId,
                                                  locationName: locationName,
                                                  latitude: geo?.latitude ?? 0,
                                                  longitude: geo?.longitude ?? 0,
                                                  radius: (radius as num).toInt(),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    // Leading gradient icon
                                                    Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFFE94560), Color(0xFFD63384)],
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: const Icon(
                                                        Icons.location_on,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                    ),

                                                    const SizedBox(width: 16),

                                                    // Location details (expand)
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            locationName,
                                                            style: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            locationAdd,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              color: Colors.white70,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            softWrap: false,
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // ✅ Trailing actions wrapped in Flexible to avoid overflow
                                                    Flexible(
                                                      fit: FlexFit.loose,
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            margin: const EdgeInsets.only(right: 8),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFE94560).withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Material(
                                                              color: Colors.transparent,
                                                              child: InkWell(
                                                                borderRadius: BorderRadius.circular(8),
                                                                onTap: () => _deleteGeofence(geofenceId, locationName),
                                                                child: const Padding(
                                                                  padding: EdgeInsets.all(8),
                                                                  child: Icon(
                                                                    Icons.delete_outline,
                                                                    color: Color(0xFFE94560),
                                                                    size: 20,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const Icon(
                                                            Icons.arrow_forward_ios,
                                                            color: Colors.white60,
                                                            size: 16,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 16),

                                                // Location details in cards
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const Text(
                                                              'Latitude',
                                                              style: TextStyle(fontSize: 12, color: Colors.white60),
                                                            ),
                                                            Text(
                                                              '${geo?.latitude?.toStringAsFixed(4) ?? "N/A"}',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const Text(
                                                              'Longitude',
                                                              style: TextStyle(fontSize: 12, color: Colors.white60),
                                                            ),
                                                            Text(
                                                              '${geo?.longitude?.toStringAsFixed(4) ?? "N/A"}',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            const Color(0xFF0F3460).withOpacity(0.8),
                                                            const Color(0xFF16213E).withOpacity(0.8),
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          const Text(
                                                            'Radius',
                                                            style: TextStyle(fontSize: 12, color: Colors.white60),
                                                          ),
                                                          Text(
                                                            '${radius}m',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFFE94560),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );

                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ---------------- Tab 2: Attendance ----------------
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AttendanceDashboardPage()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF1A1A2E),
                              const Color(0xFF16213E),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.clockRotateLeft,
                                size: 80,
                                color: Colors.white30,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Attendance Dashboard",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Coming Soon",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ---------------- Tab 3: Statistics ----------------
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                            MaterialPageRoute(
                            builder: (context) => StatisticsPage(
                          selectedDate: DateTime.now(), // today’s date
                        ),
                            ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF1A1A2E),
                              const Color(0xFF16213E),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.clockRotateLeft,
                                size: 80,
                                color: Colors.white30,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Statistics",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Coming Soon",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ---------------- Tab 4: Settings ----------------
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1A1A2E),
                            const Color(0xFF16213E),
                          ],
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Settings Header
                            Text(
                              "Settings",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Manage your app configuration",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white60,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Organization Settings Section
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF1A1A2E),
                                    Color(0xFF16213E),
                                  ],
                                ),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Settings",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "Manage your app configuration",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    // ... your existing organization card ...
                                  ],
                                ),
                              ),
                            ),

                            // Chatbot button pinned to top-right
                            Positioned(
                              top: 40, // adjust for safe area
                              right: 20,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ChatbotPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE94560),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 6,
                                ),
                                icon: const Icon(Icons.chat, color: Colors.white),
                                label: const Text(
                                  "Chatbot",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Other Settings Section (Future Features)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(0.02),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF0F3460),
                                              const Color(0xFF16213E),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.tune,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        "App Settings",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Placeholder for future settings
                                  _buildSettingItem(
                                    icon: Icons.notifications_outlined,
                                    title: "Notifications",
                                    subtitle: "Coming Soon",
                                    onTap: () {},
                                    enabled: false,
                                  ),

                                  const SizedBox(height: 12),

                                  _buildSettingItem(
                                    icon: Icons.security_outlined,
                                    title: "Security",
                                    subtitle: "Coming Soon",
                                    onTap: () {},
                                    enabled: false,
                                  ),

                                  const SizedBox(height: 12),

                                  _buildSettingItem(
                                    icon: Icons.backup_outlined,
                                    title: "Backup & Sync",
                                    subtitle: "Coming Soon",
                                    onTap: () {},
                                    enabled: false,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // App Info
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    "Smart Attendance System",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Version 1.0.0",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced Bottom navigation
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F3460),
                      const Color(0xFF16213E),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: TabBar(
                  labelColor: const Color(0xFFE94560),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE94560).withOpacity(0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  controller: _tabBarController,
                  tabs: const [
                    Tab(text: 'Home', icon: FaIcon(FontAwesomeIcons.home, size: 20)),
                    Tab(text: 'Attendance', icon: FaIcon(FontAwesomeIcons.clipboard, size: 20)),
                    Tab(text: 'Statistics', icon: Icon(Icons.analytics, size: 24)),
                    Tab(text: 'Settings', icon: Icon(Icons.settings, size: 24)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}