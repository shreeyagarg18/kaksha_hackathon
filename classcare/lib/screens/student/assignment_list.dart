import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:classcare/screens/student/assignment_card.dart';

class AssignmentList extends StatefulWidget {
  final String classId;

  const AssignmentList({super.key, required this.classId });

  @override
  _AssignmentListState createState() => _AssignmentListState();
}

class _AssignmentListState extends State<AssignmentList> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed length to 2
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

        for (var doc in snapshot.data!.docs) {
          var assignment = doc.data() as Map<String, dynamic>;
          var dueDate = DateTime.parse(assignment['dueDate']); // Ensure format is correct

          if (dueDate.isAfter(now)) {
            upcoming.add(doc);
          } else {
            past.add(doc);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Upcoming"),
                Tab(text: "Past"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSection(upcoming, "No upcoming assignments", context,widget.classId),
                  _buildSection(past, "No past assignments", context,widget.classId),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(List<QueryDocumentSnapshot> assignments, String emptyMessage, BuildContext context,String classId) {
    if (assignments.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView(
      children: assignments.map((doc) => AssignmentCard(assignment: doc , classId: classId,)).toList(),
    );
  }
}
