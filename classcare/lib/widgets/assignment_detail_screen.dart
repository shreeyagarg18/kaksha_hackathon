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
  bool _isAnalyzingAll = false;
  int _currentAnalyzing = 0;
  int _totalToAnalyze = 0;

  Future<void> _analyzeSubmission(
      String studentFileUrl, String submissionId) async {
    setState(() {
      _isAnalyzingMap = {submissionId: true};
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
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('Error analyzing submission: $e');
      }
    } finally {
      setState(() {
        _isAnalyzingMap.remove(submissionId);
      });
    }
  }

  Future<void> _analyzeAllSubmissions(
      List<QueryDocumentSnapshot> submissions) async {
    if (_isAnalyzingAll) return;

    setState(() {
      _isAnalyzingAll = true;
      _currentAnalyzing = 0;
      _totalToAnalyze = submissions.length;
    });

    try {
      String assignmentText =
          await _pdfService.extractTextFromPDF(widget.fileUrl);
      String rubricText =
          await _pdfService.extractTextFromPDF(widget.rubricUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Starting analysis of all submissions...'),
          backgroundColor: Colors.indigo.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      for (int i = 0; i < submissions.length; i++) {
        if (!mounted) break;

        var submission = submissions[i];
        String submissionId = submission.id;
        String studentId = submission['studentId'] ?? submissionId;
        String studentFileUrl = submission['fileUrl'];

        setState(() {
          _currentAnalyzing = i + 1;
        });

        try {
          String studentText =
              await _pdfService.extractTextFromPDF(studentFileUrl);

          String result = await _pdfService.sendToGeminiAPI(
              assignmentText, rubricText, studentText);

          await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('assignments')
              .doc(widget.assignmentId)
              .collection('submissions')
              .doc(submissionId)
              .update({'analysisResult': result});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Analyzed ${submission['studentName'] ?? 'Unknown'} (${i + 1}/${submissions.length})'),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.indigo.shade900,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error analyzing submission ${i + 1}: $e'),
                backgroundColor: Colors.redAccent.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('All submissions analyzed and saved to Firebase'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during analysis: $e'),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isAnalyzingAll = false;
      });
    }
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            "Analysis Result",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Text(
              result,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
              ),
              child: const Text("OK"),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime parsedDate = DateTime.parse(widget.dueDate);
    String formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.cyanAccent,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.cyanAccent,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.cyanAccent,
          linearTrackColor: Colors.indigo.shade900,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E),
                    title: const Text(
                      "Assignment Info",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    content: Text(
                      widget.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.indigo.shade900, width: 1),
              ),
              elevation: 4,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade900.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.indigo.shade800, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16, color: Colors.cyanAccent),
                              const SizedBox(width: 8),
                              Text(
                                "Due: $formattedDate",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
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
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    );
                  }

                  int submissionCount = snapshot.data!.docs.length;

                  if (submissionCount == 0) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No submissions yet",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Submissions",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.assignment_turned_in,
                                      size: 18,
                                      color: Colors.cyanAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "$submissionCount",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.auto_awesome,
                                size: 18,
                              ),
                              label: _isAnalyzingAll
                                  ? Text(
                                      'Analyzing ${_currentAnalyzing}/${_totalToAnalyze}')
                                  : const Text('Analyze All'),
                              onPressed: _isAnalyzingAll
                                  ? null
                                  : () => _analyzeAllSubmissions(
                                      snapshot.data!.docs),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _isAnalyzingAll
                                    ? Colors.indigo.shade900.withOpacity(0.5)
                                    : Colors.indigo.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isAnalyzingAll)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Processing submissions...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  Text(
                                    '${_currentAnalyzing}/${_totalToAnalyze}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _totalToAnalyze > 0
                                      ? _currentAnalyzing / _totalToAnalyze
                                      : 0,
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: submissionCount,
                          itemBuilder: (context, index) {
                            var submission = snapshot.data!.docs[index];
                            String submissionId = submission.id;
                            bool hasAnalysis = submission
                                .data()
                                .toString()
                                .contains('analysisResult');

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: hasAnalysis
                                      ? Colors.green.shade900
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              elevation: 2,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            // Leading avatar
                                            CircleAvatar(
                                              backgroundColor:
                                                  Colors.indigo.shade800,
                                              child: Text(
                                                (submission['studentName'] ??
                                                        'U')[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Student info (expanded to take available space)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    submission['studentName'] ??
                                                        'Unknown',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: Colors
                                                            .grey.shade400,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          submission['submittedAt'] !=
                                                                  null
                                                              ? DateFormat(
                                                                      'dd MMM, hh:mm a')
                                                                  .format((submission[
                                                                              'submittedAt']
                                                                          as Timestamp)
                                                                      .toDate())
                                                              : 'No submission date',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey.shade400,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (hasAnalysis)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 4),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.check_circle,
                                                            size: 14,
                                                            color: Colors.green,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            'Analysis available',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .green
                                                                  .shade300,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Action buttons in a separate row to avoid overflow
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.file_download,
                                                  color: Colors.cyanAccent,
                                                ),
                                                onPressed: () => _downloadFile(
                                                    submission['fileUrl']),
                                                tooltip: 'Download submission',
                                                constraints:
                                                    const BoxConstraints(),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: _isAnalyzingMap[
                                                            submissionId] ==
                                                        true
                                                    ? null
                                                    : () => _analyzeSubmission(
                                                        submission['fileUrl'],
                                                        submissionId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: hasAnalysis
                                                      ? Colors.green.shade900
                                                      : Colors.indigo.shade800,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                                ),
                                                child: Text(_isAnalyzingMap[
                                                            submissionId] ==
                                                        true
                                                    ? 'Analyzing...'
                                                    : hasAnalysis
                                                        ? 'View Analysis'
                                                        : 'Analyze'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasAnalysis)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade900
                                            .withOpacity(0.3),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          _showResultDialog(
                                              submission['analysisResult']);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.insights,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'View detailed analysis',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
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
      ),
    );
  }

  Widget _buildFileDownloadButton(String url, String label) {
    return InkWell(
      onTap: () => _downloadFile(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.indigo.shade900)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.description,
              color: Colors.cyanAccent,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.download,
              color: Colors.cyanAccent,
            ),
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
          SnackBar(
            content: const Text('Error opening file.'),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}