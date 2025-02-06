import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot assignment;

  const AssignmentDetailPage({super.key, required this.assignment});

  @override
  _AssignmentDetailPageState createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  bool _isSubmitting = false;

  Future<void> downloadFile(String fileUrl) async {
    final Uri uri = Uri.parse(fileUrl);
    try {
      print("hiii");

      print("hiii2");
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      print("hiii3");
    } catch (e) {
      print("ERROR");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  Future<void> uploadSubmission() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) return; // No file selected

    setState(() {
      _isSubmitting = true;
    });

    final file = result.files.single;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'assignments/${widget.assignment.id}/submissions/${file.name}');
      await storageRef.putData(file.bytes!);

      String fileUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.assignment['classId'])
          .collection('assignments')
          .doc(widget.assignment.id)
          .collection('submissions')
          .doc(widget.assignment.id)
          .set({
        'studentId': 'studentId',
        'fileUrl': fileUrl,
        'submittedAt': Timestamp.now(),
      });

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Assignment submitted successfully")),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload the file")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.assignment.data() as Map<String, dynamic>;

    String title = data['title'] ?? "No Title"; // Default value
    String description = data['description'] ?? "No Description";
    String dueDate = data['dueDate'] ?? "No Due Date";
    String? fileUrl = data['fileUrl']; // Can be null

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Due Date: $dueDate", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Description:", style: TextStyle(fontSize: 18)),
            Text(description, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Download Assignment:", style: TextStyle(fontSize: 18)),
            fileUrl != null
                ? TextButton(
                    onPressed: () => downloadFile(fileUrl),
                    child: const Text("Download File"),
                  )
                : const Text("No file available"),
            const SizedBox(height: 16),
            Text("Submit Your Assignment:", style: TextStyle(fontSize: 18)),
            ElevatedButton(
              onPressed: _isSubmitting ? null : uploadSubmission,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text("Upload Submission"),
            ),
          ],
        ),
      ),
    );
  }
}
