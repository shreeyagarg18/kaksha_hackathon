import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for formatting dates

class AssignmentUploadWidget extends StatefulWidget {
  final String classId;

  const AssignmentUploadWidget({Key? key, required this.classId}) : super(key: key);

  @override
  _AssignmentUploadWidgetState createState() => _AssignmentUploadWidgetState();
}

class _AssignmentUploadWidgetState extends State<AssignmentUploadWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick file')),
      );
    }
  }

  Future<void> uploadAssignment() async {
    if (_titleController.text.trim().isEmpty || _dueDate == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and upload a file')),
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

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('assignments/${widget.classId}/$assignmentId.pdf');

      await storageRef.putData(_pickedFile!.bytes!);
      String pdfUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc(assignmentId)
          .set({
        'assignmentId': assignmentId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': _dueDate!.toIso8601String(),
        'uploadedBy': FirebaseAuth.instance.currentUser!.uid,
        'pdfUrl': pdfUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment uploaded successfully!')),
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _dueDate = null;
        _pickedFile = null;
      });
    } catch (e) {
      print("Error uploading assignment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload assignment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload New Assignment",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Assignment Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
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
                  : "Due Date: ${DateFormat('yyyy-MM-dd').format(_dueDate!)}"),
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
          Row(
            children: [
              _pickedFile == null
                  ? const Text("No file selected")
                  : Text(_pickedFile!.name),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: pickFile,
                child: const Text("Select File"),
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
    );
  }
}
