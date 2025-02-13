import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class AssignmentUploadWidget extends StatefulWidget {
  final String classId;

  const AssignmentUploadWidget({super.key, required this.classId});

  @override
  _AssignmentUploadWidgetState createState() => _AssignmentUploadWidgetState();
}

class _AssignmentUploadWidgetState extends State<AssignmentUploadWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  PlatformFile? _pickedFile;
  String? _filePath; // Store the file path
  PlatformFile? _rubricFile;
  String? _rubricFilePath;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(withReadStream: true);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _filePath = result.files.first.path;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> pickRubric() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(withReadStream: true);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _rubricFile = result.files.first;
          _rubricFilePath = result.files.first.path;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No rubric file selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking rubric file: $e')),
      );
    }
  }

  Future<void> uploadAssignment() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _dueDate == null ||
        _pickedFile == null ||
        _rubricFile == null ||
        _filePath == null ||
        _rubricFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete all fields and upload files')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String assignmentId = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc()
          .id;

      Reference rubricStorageRef = FirebaseStorage.instance.ref().child(
          'classes/${widget.classId}/assignments/$assignmentId/rubric.pdf');
      UploadTask rubricUploadTask;

      if (kIsWeb) {
        rubricUploadTask = rubricStorageRef.putData(_rubricFile!.bytes!);
      } else {
        rubricUploadTask = rubricStorageRef.putFile(File(_rubricFilePath!));
      }

      TaskSnapshot rubricSnapshot = await rubricUploadTask;
      String rubricUrl = await rubricSnapshot.ref.getDownloadURL();

      Reference assignmentStorageRef = FirebaseStorage.instance.ref().child(
          'classes/${widget.classId}/assignments/$assignmentId/teacher_assignment.pdf');
      UploadTask assignmentUploadTask;

      if (kIsWeb) {
        assignmentUploadTask =
            assignmentStorageRef.putData(_pickedFile!.bytes!);
      } else {
        assignmentUploadTask = assignmentStorageRef.putFile(File(_filePath!));
      }

      TaskSnapshot assignmentSnapshot = await assignmentUploadTask;
      String assignmentUrl = await assignmentSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc(assignmentId)
          .set({
        'assignmentId': assignmentId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': DateFormat('yyyy-MM-dd').format(_dueDate!),
        'uploadedBy': FirebaseAuth.instance.currentUser!.uid,
        'rubricUrl': rubricUrl,
        'fileUrl': assignmentUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment uploaded successfully!')),
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _dueDate = null;
        _pickedFile = null;
        _rubricFile = null;
        _filePath = null;
        _rubricFilePath = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload assignment: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
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
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        setState(() {
                          _dueDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: const Text("Select Due Date & Time"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _pickedFile == null
                    ? const Text("No file selected")
                    : Expanded(
                        child: Text(_pickedFile!.name,
                            overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: pickFile,
                  child: const Text("Select File"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _rubricFile == null
                    ? const Text("No rubrics selected")
                    : Expanded(
                        child: Text(_rubricFile!.name,
                            overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: pickRubric,
                  child: const Text("Select Rubrics"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: uploadAssignment,
                    child: const Text("Upload Assignment"),
                  ),
          ],
        ),
      ),
    );
  }
}
