import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassDetailPage({required this.classId, required this.className});

  @override
  _ClassDetailPageState createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  final TextEditingController _assignmentTitleController = TextEditingController();
  final TextEditingController _assignmentDescriptionController = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _assignmentTitleController.dispose();
    _assignmentDescriptionController.dispose();
    super.dispose();
  }

  // Upload Assignment Function
  Future<void> uploadAssignment() async {
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    try {
      String assignmentId = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc()
          .id;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc(assignmentId)
          .set({
        'assignmentId': assignmentId,
        'title': _assignmentTitleController.text.trim(),
        'description': _assignmentDescriptionController.text.trim(),
        'dueDate': _dueDate!.toIso8601String(),
        'uploadedBy': FirebaseAuth.instance.currentUser!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment uploaded successfully!')),
      );
      _assignmentTitleController.clear();
      _assignmentDescriptionController.clear();
      setState(() {
        _dueDate = null;
      });
    } catch (e) {
      print("Error uploading assignment: $e");
    }
  }

  // Show Room Code Popup
  
void showRoomCodePopup() async {
  try {
    // Fetch the join code from Firestore
    DocumentSnapshot classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();

    String joinCode = classDoc['joinCode'] ?? 'No Join Code Available';

    // Show the join code in a dialog box
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Code"),
        content: Row(
          children: [
            Expanded(
              child: Text(
                joinCode,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: joinCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Join code copied to clipboard!")),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Current Assignments",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
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
                        child: ListTile(
                          title: Text(assignment['title']),
                          subtitle: Text("Due Date: ${assignment['dueDate']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(assignment['title']),
                                  content: Text(
                                      "Description: ${assignment['description']}\nDue Date: ${assignment['dueDate']}"),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Upload New Assignment",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _assignmentTitleController,
              decoration: const InputDecoration(
                labelText: 'Assignment Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _assignmentDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Assignment Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(_dueDate == null
                    ? "No due date selected"
                    : "Due Date: ${_dueDate!.toLocal()}".split(' ')[0]),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dueDate = pickedDate;
                      });
                    }
                  },
                  child: const Text("Select Due Date"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: uploadAssignment,
              child: const Text("Upload Assignment"),
            ),
          ],
        ),
      ),
    );
  }
}
