import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot assignment;
  final String classId;

  AssignmentDetailPage({super.key, required this.assignment, required this.classId});

  @override
  _AssignmentDetailPageState createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  bool _isSubmitting = false;
  PlatformFile? _pickedFile;
  String? _filePath;
  bool _isSubmitted = false;
  String? _submittedFileUrl;
  String? _submittedFileName;

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
  }

  // Check if the assignment has been submitted by the student
  Future<void> _checkSubmissionStatus() async {
    try {
      String studentId = FirebaseAuth.instance.currentUser!.uid;

      var submissionSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc(widget.assignment['assignmentId'])
          .collection('submissions')
          .doc(studentId)
          .get();

      if (submissionSnapshot.exists) {
        setState(() {
          _isSubmitted = true;
          _submittedFileUrl = submissionSnapshot['fileUrl'];
          _submittedFileName = _submittedFileUrl?.split('/').last ?? "Submitted File";
        });
      }
    } catch (e) {
      print("Error checking submission status: $e");
    }
  }

  Future<void> downloadFile(String fileUrl) async {
    final Uri uri = Uri.parse(fileUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

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

  Future<void> uploadSubmission() async {
    if (_pickedFile == null || _filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file before submitting')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String studentId = FirebaseAuth.instance.currentUser!.uid;
      String studentName = await FirebaseFirestore.instance.collection('users').doc(studentId).get().then((doc) => doc['name'] ?? 'No name found');

      String fileExtension = _pickedFile!.extension ?? 'pdf';

      Reference storageRef = FirebaseStorage.instance.ref().child(
    'classes/${widget.classId}/assignments/${widget.assignment['assignmentId']}/student/${_pickedFile!.name}');


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
          .doc(widget.assignment['assignmentId'])
          .collection('submissions')
          .doc(studentId)
          .set({
            'studentName':studentName,
        'studentId': studentId,
        'fileUrl': fileUrl,
        'submittedAt': Timestamp.now(),
      });

      setState(() {
        _isSubmitted = true;
        _submittedFileUrl = fileUrl;
        _submittedFileName = _pickedFile!.name;
        _pickedFile = null;
        _filePath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit assignment: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
   Widget build(BuildContext context) {
    var data = widget.assignment.data() as Map<String, dynamic>;
    String title = data['title'] ?? "No Title";
    String description = data['description'] ?? "No Description";
    String dueDate = data['dueDate'] ?? "No Due Date";
    String? fileUrl = data['fileUrl'];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Due Date Banner
            Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Due: $dueDate",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Assignment File Download Section
                  if (fileUrl != null)
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.assignment),
                        title: const Text("Assignment File"),
                        subtitle: const Text("Click to download"),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => downloadFile(fileUrl),
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 24),
                  
                  // Submission Status Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isSubmitted ? Icons.check_circle : Icons.pending,
                                color: _isSubmitted ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isSubmitted ? "Submitted" : "Pending Submission",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isSubmitted ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (!_isSubmitted) ...[
                            // File Selection Area
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _pickedFile?.name ?? "No file selected",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: pickFile,
                                        icon: const Icon(Icons.attach_file,color: Colors.white,),
                                        label: const Text("Choose File" , style: TextStyle(color: Colors.white),),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : uploadSubmission,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Submit Assignment",
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ] else ...[
                            // Submitted File Section
                            ListTile(
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(_submittedFileName ?? "Submitted File"),
                              trailing: IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: _submittedFileUrl != null
                                    ? () => downloadFile(_submittedFileUrl!)
                                    : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}