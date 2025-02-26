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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: "Assignments"),
            Tab(icon: Icon(Icons.chat), text: "Chat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AssignmentList(classId: widget.classId),
          ChatTab(classId: widget.classId),
        ],
      ),
    );
  }
}
