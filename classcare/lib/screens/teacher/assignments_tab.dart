import 'package:classcare/widgets/assignment_upload_widget.dart';
import 'package:flutter/material.dart';
import 'package:classcare/widgets/teacher_assignment_list.dart';


class AssignmentsTab extends StatefulWidget {
  final String classId;

  const AssignmentsTab({super.key, required this.classId});

  @override
  _AssignmentsTabState createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<AssignmentsTab>
    with SingleTickerProviderStateMixin {
  late TabController _assignmentTabController;

  @override
  void initState() {
    super.initState();
    _assignmentTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _assignmentTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _assignmentTabController,
          tabs: const [
            Tab(text: "Current Assignments"),
            Tab(text: "Past Assignments"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _assignmentTabController,
            children: [
              AssignmentList(classId: widget.classId, isCurrent: true),
              AssignmentList(classId: widget.classId, isCurrent: false),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AssignmentUploadWidget(classId: widget.classId),
                ),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Assignment"),
          ),
        ),
      ],
    );
  }
}
