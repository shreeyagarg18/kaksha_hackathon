import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'analyze.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String classId;
  final String assignmentId;
  final String title;
  final String description;
  final String dueDate;
  final String fileUrl;
  final String rubricUrl;

  const AssignmentDetailScreen({
    super.key,
    required this.classId,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.fileUrl,
    required this.rubricUrl,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final PDFUploadService _pdfService = PDFUploadService();
  Map<String, bool> _isAnalyzingMap = {};

  Future<void> _analyzeSubmission(
      String studentFileUrl, String submissionId) async {
    setState(() {
      _isAnalyzingMap = {
        submissionId: true
      }; // Only mark the clicked submission as analyzing
    });

    try {
      String assignmentText =
          await _pdfService.extractTextFromPDF(widget.fileUrl);
      String rubricText =
          await _pdfService.extractTextFromPDF(widget.rubricUrl);
      String studentText = await _pdfService.extractTextFromPDF(studentFileUrl);

      String result = await _pdfService.sendToGeminiAPI(
          assignmentText, rubricText, studentText);

      if (mounted) {
        _showResultDialog(result); // Show result in a dialog box
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
            'Error analyzing submission: $e'); // Show error in dialog
      }
    } finally {
      setState(() {
        _isAnalyzingMap.remove(submissionId);
      });
    }
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Analysis Result"),
          content: SingleChildScrollView(
            child: Text(result),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime parsedDate = DateTime.parse(widget.dueDate);
    String formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.description),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text("Due: $formattedDate"),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildFileDownloadButton(widget.fileUrl, "View Assignment"),
                if (widget.rubricUrl.isNotEmpty)
                  _buildFileDownloadButton(widget.rubricUrl, "View Rubric"),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('assignments')
                  .doc(widget.assignmentId)
                  .collection('submissions')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                int submissionCount = snapshot.data!.docs.length;
                print("NUMBER_SUBMISSIONS: $submissionCount");

                if (submissionCount == 0) {
                  return const Center(child: Text("No submissions yet"));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "NUMBER_SUBMISSIONS: $submissionCount",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: submissionCount,
                        itemBuilder: (context, index) {
                          var submission = snapshot.data!.docs[index];
                          String submissionId = submission.id;
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(
                                      submission['studentName'] ?? 'Unknown'),
                                  subtitle: Text(
                                      submission['submittedAt'] != null
                                          ? DateFormat('dd MMM, hh:mm a')
                                              .format((submission['submittedAt']
                                                      as Timestamp)
                                                  .toDate())
                                          : 'No submission date'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () => _downloadFile(
                                            submission['fileUrl']),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            _isAnalyzingMap[submissionId] ==
                                                    true
                                                ? null
                                                : () => _analyzeSubmission(
                                                    submission['fileUrl'],
                                                    submissionId),
                                        child: Text(
                                            _isAnalyzingMap[submissionId] ==
                                                    true
                                                ? 'Analyzing...'
                                                : 'Analyze'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileDownloadButton(String url, String label) {
    return InkWell(
      onTap: () => _downloadFile(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Icon(Icons.file_present, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.download, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening file.')),
        );
      }
    }
  }
}
