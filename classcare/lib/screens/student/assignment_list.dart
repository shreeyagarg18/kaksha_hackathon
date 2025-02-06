import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:classcare/screens/student/assignment_card.dart';

class AssignmentList extends StatefulWidget {
  final String classId;

  const AssignmentList({super.key, required this.classId});

  @override
  _AssignmentListState createState() => _AssignmentListState();
}

class _AssignmentListState extends State<AssignmentList> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No assignments available"));
        }

        var now = DateTime.now();
        List<QueryDocumentSnapshot> upcoming = [];
        List<QueryDocumentSnapshot> past = [];
        List<QueryDocumentSnapshot> due = [];

        for (var doc in snapshot.data!.docs) {
          var assignment = doc.data() as Map<String, dynamic>;
          var dueDate = DateTime.parse(assignment['dueDate']); // Ensure format is correct

          if (dueDate.isAfter(now)) {
            upcoming.add(doc);
          } else if (dueDate.isBefore(now)) {
            past.add(doc);
          } else {
            due.add(doc);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Upcoming"),
                Tab(text: "Due Today"),
                Tab(text: "Past"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSection(upcoming, "No upcoming assignments", context),
                  _buildSection(due, "No due assignments", context),
                  _buildSection(past, "No past assignments", context),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(List<QueryDocumentSnapshot> assignments, String emptyMessage, BuildContext context) {
    if (assignments.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView(
      children: assignments.map((doc) => AssignmentCard(assignment: doc)).toList(),
    );
  }
}
