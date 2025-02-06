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

  const AssignmentUploadWidget({Key? key, required this.classId})
      : super(key: key);

  @override
  _AssignmentUploadWidgetState createState() => _AssignmentUploadWidgetState();
}

class _AssignmentUploadWidgetState extends State<AssignmentUploadWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  PlatformFile? _pickedFile;
<<<<<<< HEAD
  String? _filePath; // Store the file path
=======
  String? _filePath;
  bool _isUploading = false;
>>>>>>> a85976cddead7877366701f0645a60f769311d5a

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    try {
<<<<<<< HEAD
      FilePickerResult? result = await FilePicker.platform.pickFiles(withReadStream: true); 
=======
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(withReadStream: true);
>>>>>>> a85976cddead7877366701f0645a60f769311d5a

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
<<<<<<< HEAD
          _filePath = result.files.first.path; // Store file path for upload
=======
          _filePath = result.files.first.path;
>>>>>>> a85976cddead7877366701f0645a60f769311d5a
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

<<<<<<< HEAD
    Future<void> uploadAssignment() async {
  if (_titleController.text.trim().isEmpty ||
      _descriptionController.text.trim().isEmpty ||
      _dueDate == null ||
      _pickedFile == null ||
      _filePath == null) {
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

    // ✅ Get the correct file extension
    String fileExtension = _pickedFile!.extension ?? 'unknown';
    
    if (fileExtension == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File type not recognized')),
=======
  Future<void> uploadAssignment() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _dueDate == null ||
        _pickedFile == null ||
        _filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete all fields and upload a file')),
>>>>>>> a85976cddead7877366701f0645a60f769311d5a
      );
      return;
    }

<<<<<<< HEAD
    // ✅ Save file with original extension
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('assignments/${widget.classId}/$assignmentId.$fileExtension');

    UploadTask uploadTask;
    
    // ✅ Handle file upload differently for Web and Mobile
    if (kIsWeb) {
      uploadTask = storageRef.putData(_pickedFile!.bytes!);
    } else {
      uploadTask = storageRef.putFile(File(_filePath!));
=======
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

      String fileExtension = _pickedFile!.extension ?? 'unknown';

      if (fileExtension == 'unknown') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File type not recognized')),
        );
        return;
      }

      Reference storageRef = FirebaseStorage.instance.ref().child(
          'assignments/${widget.classId}/$assignmentId/$assignmentId.$fileExtension');

      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = storageRef.putData(_pickedFile!.bytes!);
      } else {
        uploadTask = storageRef.putFile(File(_filePath!));
      }

      TaskSnapshot snapshot = await uploadTask;
      String fileUrl = await snapshot.ref.getDownloadURL();

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
        'fileUrl': fileUrl,
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
        _filePath = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload assignment: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
>>>>>>> a85976cddead7877366701f0645a60f769311d5a
    }

    TaskSnapshot snapshot = await uploadTask;
    String fileUrl = await snapshot.ref.getDownloadURL();

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
      'fileUrl': fileUrl, // ✅ Store the correct file URL
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
      _filePath = null;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload assignment: $e')),
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
<<<<<<< HEAD
                  : Expanded(child: Text(_pickedFile!.name, overflow: TextOverflow.ellipsis)),
=======
                  : Expanded(
                      child: Text(_pickedFile!.name,
                          overflow: TextOverflow.ellipsis)),
>>>>>>> a85976cddead7877366701f0645a60f769311d5a
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: pickFile,
                child: const Text("Select File"),
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
    );
  }
}
