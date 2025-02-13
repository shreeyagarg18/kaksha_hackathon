import 'package:classcare/widgets/analyze.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String classId;
  final String assignmentId;
  final String title;
  final String description;
  final String dueDate;
  final String fileUrl;

  const AssignmentDetailScreen({
    super.key,
    required this.classId,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.fileUrl,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  void _handlePDFUpload(String fileUrl) {
    PDFUploadService pdfUploadService = PDFUploadService();
    print("upload");
    pdfUploadService.uploadPDF(fileUrl, (String result) {
      // Handle the result (show it in a SnackBar or display on the screen)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    });
  }

  Future<List<Map<String, dynamic>>> fetchSubmissions() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('assignments')
        .doc(widget.assignmentId)
        .collection('submissions')
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    DateTime parsedDate = DateTime.parse(widget.dueDate);
    String formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.isEmpty ? 'No title' : widget.title),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Implement edit assignment functionality
            },
            tooltip: 'Edit Assignment',
          ),
        ],
      ),
      body: Column(
        children: [
          // Assignment Info Card
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Assignment Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.description.isEmpty
                            ? 'No description provided'
                            : widget.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Set for $formattedDate",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Assignment File Button
                InkWell(
                  onTap: () async {
                    final Uri uri = Uri.parse(widget.fileUrl);
                    try {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error opening file.')),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_present_outlined,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "View Assignment File",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.download_outlined,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Submissions Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  "Student Submissions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Submissions List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchSubmissions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No submissions yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    var submission = snapshot.data![index];
                    String studentName = submission['studentName'] ?? 'No name';
                    String studentFileUrl = submission['fileUrl'] ?? '';
                    Timestamp? submittedAt =
                        submission['submittedAt'] as Timestamp?;
                    String submittedDate = submittedAt != null
                        ? DateFormat('dd MMM, hh:mm a')
                            .format(submittedAt.toDate())
                        : 'Date not available';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                studentName.isNotEmpty
                                    ? studentName[0].toUpperCase()
                                    : 'N',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              studentName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              "Submitted on $submittedDate",
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.download_outlined),
                              onPressed: () async {
                                final Uri uri = Uri.parse(studentFileUrl);
                                try {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Error downloading file.')),
                                    );
                                  }
                                }
                              },
                              tooltip: 'Download submission',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: TextButton(
                              onPressed: () {
                                // Pass the student's file URL to the PDF upload method
                                String studentFileUrl =
                                    submission['fileUrl'] ?? '';
                                _handlePDFUpload(studentFileUrl);
                                print(studentFileUrl);
                              },
                              child: const Text('Analyze'),
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
        ],
      ),
    );
  }
}
