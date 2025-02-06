import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(icon: Icon(Icons.upload_file), text: "Upload Assignment"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Section for Current Assignments
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('assignments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No assignments uploaded."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var assignment = snapshot.data!.docs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionTile(
                        title: Text(assignment['title']),
                        subtitle: Text("Due Date: ${assignment['dueDate']}"),
                        children: [
                          ListTile(
                            title: const Text("Description:"),
                            subtitle: Text(assignment['description']),
                          ),
                          ListTile(
                            title: const Text("Download PDF:"),
                            trailing: IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () async {
                                String pdfUrl = assignment['pdfUrl'];
                                await launchUrl(Uri.parse(pdfUrl));
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Section for Uploading New Assignment
          AssignmentUploadWidget(classId: widget.classId),
        ],
      ),
    );
  }
}
