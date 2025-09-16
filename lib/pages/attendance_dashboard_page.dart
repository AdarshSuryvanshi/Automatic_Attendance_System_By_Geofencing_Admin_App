import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

// Ensure Firebase is initialized in your app entrypoint before using this widget.
// For Web/Android, generate firebase_options.dart with FlutterFire CLI and call
// Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); [Docs refs]

class AttendanceDashboardPage extends StatefulWidget {
  const AttendanceDashboardPage({super.key});

  @override
  State<AttendanceDashboardPage> createState() => _AttendanceDashboardPageState();
}

class _AttendanceDashboardPageState extends State<AttendanceDashboardPage> {
  // RTDB instance pointing to your regional database
  late final FirebaseDatabase rtdb;

  DateTime selectedDate = DateTime.now();
  String selectedGeofenceId = 'all';
  List<String> geofenceOptions = ['all'];
  Map<String, String> geofenceNames = {'all': 'All Locations'};

  @override
  void initState() {
    super.initState();
    // Point explicitly to your RTDB instance (Asia-Southeast1)
    rtdb = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://geofenceat-default-rtdb.asia-southeast1.firebasedatabase.app',
    ); // Using an explicit URL is recommended when multiple DBs/regions exist [2][3].

    _loadGeofences(); // Firestore geofence list [1].
  }

  // Load geofences from Firestore
  Future<void> _loadGeofences() async {
    try {
      final qs = await FirebaseFirestore.instance.collection('geofences').get(); // [1]
      setState(() {
        geofenceOptions = ['all'];
        geofenceNames = {'all': 'All Locations'};
        for (final d in qs.docs) {
          final data = d.data();
          geofenceOptions.add(d.id);
          geofenceNames[d.id] = (data['location_name'] ?? 'Unknown Location').toString();
        }
      });
    } catch (e) {
      debugPrint('Error loading geofences: $e');
    }
  }

  String _dateKey(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _fmtIsoToTime(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--';
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'present':
        return const Color(0xFF28A745);
      case 'absent':
        return const Color(0xFFDC3545);
      case 'outside_geofence':
        return const Color(0xFFFFC107);
      default:
        return Colors.white60;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE94560),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  // Core: Combine Firestore employees by geofence with RTDB attendance for the date
  Stream<List<Map<String, dynamic>>> _attendanceStream() {
    final dateKey = _dateKey(selectedDate);

    final employeesQuery = (selectedGeofenceId == 'all')
        ? FirebaseFirestore.instance.collection('employees')
        : FirebaseFirestore.instance
        .collection('employees')
        .where('geofence_id', isEqualTo: selectedGeofenceId); // Firestore filter by geofence [1].

    return employeesQuery.snapshots().asyncMap((empSnap) async {
      final employees = empSnap.docs
          .map((d) => {
        'phone': d.id,
        'name': (d.data()['name'] ?? d.id).toString(),
      })
          .toList();

      if (employees.isEmpty) return <Map<String, dynamic>>[];

      final dateRef = rtdb.ref('attendance/$dateKey'); // RTDB path for date [3].

      final List<Map<String, dynamic>> rows = [];
      await Future.wait(employees.map((e) async {
        final phone = e['phone'] as String;
        final name = e['name'] as String;
        final snap = await dateRef.child(phone).get(); // Point read by key [3].

        if (!snap.exists) {
          // If you prefer to hide absences, comment this block.
          rows.add({
            'employeeName': name,
            'employeeId': phone,
            'data': {
              'check_in': null,
              'check_out': null,
              'total_hours': 0.0,
              'status': 'absent',
              'name': name,
            },
          });
          return;
        }
        final m = Map<String, dynamic>.from(snap.value as Map);
        rows.add({
          'employeeName': name,
          'employeeId': phone,
          'data': {
            'check_in': m['check_in'],
            'check_out': m['check_out'],
            'total_hours': (m['total_hours'] is num)
                ? (m['total_hours'] as num).toDouble()
                : double.tryParse('${m['total_hours']}') ?? 0.0,
            'status': (m['status'] ?? '').toString(),
            'name': (m['name'] ?? name).toString(),
          },
        });
      }));

      rows.sort((a, b) => (a['employeeName'] as String).compareTo(b['employeeName'] as String));
      return rows;
    }); // Combining Firestore stream with RTDB reads keeps cross-db logic simple and efficient [4][5].
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: Column(
        children: [
          // Header / Filters
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F3460), // solid fill instead of gradient
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),

            child: Column(
              children: [
                Row(
                  children: const [
                    
                    SizedBox(width: 12),
                    Text(
                      'Attendance Dashboard',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Date picker
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _pickDate,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFFE94560), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Date', style: TextStyle(fontSize: 12, color: Colors.white60)),
                                        Text(
                                          DateFormat('dd MMM yyyy').format(selectedDate),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Geofence dropdown
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedGeofenceId,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF16213E),
                              style: const TextStyle(color: Colors.white),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white60),
                              onChanged: (v) => setState(() => selectedGeofenceId = v ?? 'all'),
                              items: geofenceOptions.map((id) {
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Color(0xFFE94560), size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            geofenceNames[id] ?? 'Unknown',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _attendanceStream(),
              builder: (context, snap) {
                final records = snap.data ?? <Map<String, dynamic>>[];
                int total = records.length;
                int present = records.where((r) => (r['data']['status'] ?? '').toString().toLowerCase() == 'present').length;
                int absent = total - present;
                return _statsRow(present: present, total: total, absent: absent);
              },
            ),
          ),

          const SizedBox(height: 20),

          // Table
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05), // flat bg
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFE94560).withOpacity(0.2), Colors.transparent],
                      ),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Employee', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))),
                        Expanded(flex: 2, child: Text('Check In', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))),
                        Expanded(flex: 2, child: Text('Check Out', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))),
                        Expanded(flex: 2, child: Text('Hours', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))),
                        Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _attendanceStream(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560))),
                          );
                        }
                        final rows = snap.data ?? <Map<String, dynamic>>[];
                        if (rows.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_busy, size: 60, color: Colors.white30),
                                const SizedBox(height: 12),
                                Text(
                                  'No attendance for ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, i) => _attendanceRow(rows[i], i),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statsRow({required int present, required int total, required int absent}) {
    Widget card(String title, String value, Color color, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: card('Present', present.toString(), const Color(0xFF28A745), Icons.check_circle)),
        const SizedBox(width: 12),
        Expanded(child: card('Total', total.toString(), const Color(0xFFE94560), Icons.people)),
        const SizedBox(width: 12),
        Expanded(child: card('Absent', absent.toString(), const Color(0xFFDC3545), Icons.cancel)),
      ],
    );
  }

  Widget _attendanceRow(Map<String, dynamic> attendanceRecord, int index) {
    final data = attendanceRecord['data'] as Map<String, dynamic>;
    final employeeName = (attendanceRecord['employeeName'] ?? '').toString();
    final checkInIso = data['check_in'] as String?;
    final checkOutIso = data['check_out'] as String?;
    final hours = (data['total_hours'] is num)
        ? (data['total_hours'] as num).toDouble()
        : double.tryParse('${data['total_hours']}') ?? 0.0;
    final status = (data['status'] ?? 'absent').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFE94560), Color(0xFFD63384)]),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    employeeName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmtIsoToTime(checkInIso), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmtIsoToTime(checkOutIso), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text(hours.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor(status).withOpacity(0.5)),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
