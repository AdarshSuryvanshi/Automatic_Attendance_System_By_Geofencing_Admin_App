import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

import 'stats_page.dart';

class StatisticsPage extends StatefulWidget {
  final DateTime selectedDate;
  const StatisticsPage({super.key, required this.selectedDate});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    "https://geofenceat-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("attendance");

  int present = 0;
  int absent = 0;
  int late = 0;
  int earlyLeave = 0;
  bool isLoading = true;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      isLoading = true;
      present = 0;
      absent = 0;
      late = 0;
      earlyLeave = 0;
    });

    String dateKey = DateFormat("yyyy-MM-dd").format(selectedDate);

    final snapshot = await dbRef.child(dateKey).get();

    if (snapshot.exists) {
      Map data = snapshot.value as Map;

      data.forEach((employeeId, record) {
        final checkIn = record["checkIn"];
        final checkOut = record["checkOut"];

        // If no check-in and no check-out, employee is absent
        if (checkIn == null && checkOut == null) {
          absent++;
        } else {
          // Employee is present (has either check-in or check-out)
          present++;

          // Check if late (check-in after 10:00)
          if (checkIn != null) {
            try {
              final checkInTime = DateFormat("HH:mm").parse(checkIn);
              final lateThreshold = DateFormat("HH:mm").parse("10:00");
              if (checkInTime.isAfter(lateThreshold)) {
                late++;
              }
            } catch (e) {
              print("Error parsing check-in time: $checkIn");
            }
          }

          // Check if early leave (check-out before 18:00)
          if (checkOut != null) {
            try {
              final checkOutTime = DateFormat("HH:mm").parse(checkOut);
              final earlyThreshold = DateFormat("HH:mm").parse("18:00");
              if (checkOutTime.isBefore(earlyThreshold)) {
                earlyLeave++;
              }
            } catch (e) {
              print("Error parsing check-out time: $checkOut");
            }
          }
        }
      });
    }

    setState(() => isLoading = false);
  }

  List<PieChartSectionData> _getPieChartSections() {
    List<PieChartSectionData> sections = [];

    if (present > 0) {
      sections.add(PieChartSectionData(
        color: Colors.green,
        value: present.toDouble(),
        title: "Present\n$present",
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    if (absent > 0) {
      sections.add(PieChartSectionData(
        color: Colors.red,
        value: absent.toDouble(),
        title: "Absent\n$absent",
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    if (late > 0) {
      sections.add(PieChartSectionData(
        color: Colors.orange,
        value: late.toDouble(),
        title: "Late\n$late",
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    if (earlyLeave > 0) {
      sections.add(PieChartSectionData(
        color: Colors.blue,
        value: earlyLeave.toDouble(),
        title: "Early Leave\n$earlyLeave",
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final total = present + absent;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Date & picker button
            Text(
              "Date: ${DateFormat("yyyy-MM-dd").format(selectedDate)}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text("Change Date"),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                  _fetchAttendanceData();
                }
              },
            ),

            const SizedBox(height: 20),

            // Summary statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Total Employees: $total",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem("Present", present, Colors.green),
                        _buildStatItem("Absent", absent, Colors.red),
                        _buildStatItem("Late", late, Colors.orange),
                        _buildStatItem("Early Leave", earlyLeave, Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Pie chart
            if (total > 0)
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: _getPieChartSections(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                  ),
                ),
              )
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "No attendance data available for this date",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Button to go to employee stats
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmployeeStatsPage(month: selectedDate),
                  ),
                );
              },
              child: const Text("View Per Employee Stats"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}