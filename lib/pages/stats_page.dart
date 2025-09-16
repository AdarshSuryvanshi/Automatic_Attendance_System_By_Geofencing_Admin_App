import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';


class EmployeeStatsPage extends StatefulWidget {
  final DateTime month;
  const EmployeeStatsPage({super.key, required this.month});

  @override
  State<EmployeeStatsPage> createState() => _EmployeeStatsPageState();
}

class _EmployeeStatsPageState extends State<EmployeeStatsPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    "https://geofenceat-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("attendance");

  Map<String, Map<String, int>> employeeStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyData();
  }

  Future<void> _fetchMonthlyData() async {
    String monthKey = DateFormat("yyyy-MM").format(widget.month);

    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      Map data = snapshot.value as Map;

      data.forEach((dateKey, dailyData) {
        if (dateKey.toString().startsWith(monthKey)) {
          Map empData = dailyData as Map;
          empData.forEach((employeeId, record) {
            final checkIn = record["checkIn"];
            final checkOut = record["checkOut"];

            employeeStats.putIfAbsent(employeeId, () => {
              "present": 0,
              "absent": 0,
              "late": 0,
              "early": 0,
            });

            if (checkIn == null && checkOut == null) {
              employeeStats[employeeId]!["absent"] =
                  employeeStats[employeeId]!["absent"]! + 1;
            } else {
              employeeStats[employeeId]!["present"] =
                  employeeStats[employeeId]!["present"]! + 1;

              if (checkIn != null) {
                final checkInTime = DateFormat("HH:mm").parse(checkIn);
                if (checkInTime.isAfter(DateFormat("HH:mm").parse("10:00"))) {
                  employeeStats[employeeId]!["late"] =
                      employeeStats[employeeId]!["late"]! + 1;
                }
              }

              if (checkOut != null) {
                final checkOutTime = DateFormat("HH:mm").parse(checkOut);
                if (checkOutTime.isBefore(DateFormat("HH:mm").parse("18:00"))) {
                  employeeStats[employeeId]!["early"] =
                      employeeStats[employeeId]!["early"]! + 1;
                }
              }
            }
          });
        }
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Employee Stats (${DateFormat("yyyy-MM").format(widget.month)})"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : employeeStats.isEmpty
          ? const Center(child: Text("No data found for this month"))
          : ListView.builder(
        itemCount: employeeStats.length,
        itemBuilder: (context, index) {
          String empId = employeeStats.keys.elementAt(index);
          Map<String, int> stats = employeeStats[empId]!;

          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Employee: $empId",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat("Present", stats["present"]!, Colors.green),
                      _buildStat("Absent", stats["absent"]!, Colors.red),
                      _buildStat("Late", stats["late"]!, Colors.orange),
                      _buildStat("Early", stats["early"]!, Colors.blue),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Mini bar chart
                  SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text("P");
                                  case 1:
                                    return const Text("A");
                                  case 2:
                                    return const Text("L");
                                  case 3:
                                    return const Text("E");
                                }
                                return const Text("");
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _makeBarGroup(0, stats["present"]!.toDouble(), Colors.green),
                          _makeBarGroup(1, stats["absent"]!.toDouble(), Colors.red),
                          _makeBarGroup(2, stats["late"]!.toDouble(), Colors.orange),
                          _makeBarGroup(3, stats["early"]!.toDouble(), Colors.blue),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(value.toString(), style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: color, width: 20),
      ],
    );
  }
}

