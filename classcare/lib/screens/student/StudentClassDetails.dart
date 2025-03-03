import 'package:classcare/screens/student/attendance_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:classcare/screens/student/assignment_list.dart';
import 'package:classcare/screens/teacher/chat_tab.dart';

class StudentClassDetails extends StatefulWidget {
  final String classId;
  final String className;

  const StudentClassDetails({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  _StudentClassDetailsState createState() => _StudentClassDetailsState();
}

class _StudentClassDetailsState extends State<StudentClassDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> getClassDetails() async {
    return FirebaseFirestore.instance.collection('classes').doc(widget.classId).get();
  }
  
  void _giveAttendance() {
    // TODO: Implement the attendance functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance recorded successfully!')),
    );
    Navigator.push(context, MaterialPageRoute(builder: (context)=>AttendanceScreen(classId: widget.classId, className: widget.className)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        // No bottom TabBar here, we'll add it separately
      ),
      body: Column(
        children: [
          // Give Attendance Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _giveAttendance,
              icon: const Icon(Icons.check_circle),
              label: const Text('Give Attendance'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48), // sets the button height
              ),
            ),
          ),
          // Custom TabBar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.assignment), text: "Assignments"),
              Tab(icon: Icon(Icons.chat), text: "Chat"),
            ],
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AssignmentList(classId: widget.classId),
                ChatTab(classId: widget.classId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}