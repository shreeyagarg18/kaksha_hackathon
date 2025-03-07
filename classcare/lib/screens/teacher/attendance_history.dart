import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceHistory extends StatefulWidget {
  final String classId; // Accept classId as a parameter

  const AttendanceHistory({super.key, required this.classId});

  @override
  _AttendanceHistory createState() => _AttendanceHistory();
}

class _AttendanceHistory extends State<AttendanceHistory> {
  // Function to fetch attendance data from Firestore
  Stream<Map<String, dynamic>> fetchAttendanceHistory() {
    return FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('attendancehistory')
        .snapshots()
        .map((snapshot) {
      final data = <String, dynamic>{};
      for (var doc in snapshot.docs) {
        data[doc.id] = doc.data();
      }
      return data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: fetchAttendanceHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No attendance history available."));
          }

          final attendanceData = snapshot.data!;
          return ListView.builder(
            itemCount: attendanceData.length,
            itemBuilder: (context, index) {
              final date = attendanceData.keys.elementAt(index);
              final students = attendanceData[date] as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(
                    "Date: $date",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: students.entries.map((entry) {
                    final studentId = entry.key;
                    final details = entry.value as Map<String, dynamic>;
                    return ListTile(
                      title: Text(details['name'] ?? 'Unknown'),
                      subtitle: Text(
                          "Time: ${details['time'] ?? 'N/A'}"),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
