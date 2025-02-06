import 'package:classcare/widgets/teacher_assignment_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classcare/widgets/assignment_upload_widget.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassDetailPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  _ClassDetailPageState createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> showRoomCodePopup() async {
    try {
      DocumentSnapshot classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();

      String joinCode = classDoc['joinCode'] ?? 'No Join Code Available';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Join Code"),
          content: Row(
            children: [
              Expanded(
                child: Text(
                  joinCode,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: joinCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Join code copied to clipboard!")),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error fetching join code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch join code.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Class: ${widget.className}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: showRoomCodePopup,
            tooltip: "Show Room Code",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: "Current Assignments"),
            Tab(icon: Icon(Icons.assignment), text: "Past Assignment"),
            Tab(icon: Icon(Icons.upload_file), text: "Upload Assignment"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Section for Current Assignments
          AssignmentList(
            classId: widget.classId,
            isCurrent: true, // Show current assignments
          ),

          // Past Assignments
          AssignmentList(
            classId: widget.classId,
            isCurrent: false, // Show past assignments
          ),
          AssignmentUploadWidget(classId: widget.classId),
        ],
      ),
    );
  }
}
