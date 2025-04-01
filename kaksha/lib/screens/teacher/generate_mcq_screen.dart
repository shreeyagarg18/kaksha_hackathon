import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class GenerateMCQScreen extends StatefulWidget {
  @override
  _GenerateMCQScreenState createState() => _GenerateMCQScreenState();
}

class _GenerateMCQScreenState extends State<GenerateMCQScreen> {
  final TextEditingController _numQuestionsController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _numQuestionsController.dispose();
    _topicController.dispose();
    _difficultyController.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<String> fetchMCQsFromGemini(
      int numQuestions, String topic, String difficulty) async {
    var apiKey =  dotenv.env['API_KEY_5'] ?? '';
    var url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    String prompt = """
      Generate strictly $numQuestions multiple-choice questions on the topic '$topic' with difficulty level '$difficulty'.
      Each question should have four options labeled 0, 1, 2, and 3, with one correct answer.
      Try to make length of the questions and options to be small.
      Return the output in a structured CSV format:
      Question,Option 0,Option 1,Option 2,Option 3,Answer
      Ensure that:
      - Each field is separated by a comma.
      - There are no extra line breaks inside a field.
      - Use double quotes to enclose any field containing a comma.
    """;

    final requestPayload = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'].isNotEmpty) {
          var firstCandidate = jsonResponse['candidates'][0];
          if (firstCandidate.containsKey('content')) {
            var content = firstCandidate['content'];
            if (content.containsKey('parts') && content['parts'].isNotEmpty) {
              return content['parts']
                  .map<String>((part) => part['text'].toString())
                  .join("\n");
            }
          }
        }
        return 'No valid content found in API response.';
      } else {
        return 'Error: ${response.statusCode}, Response: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> generateAndSaveCSV() async {
    setState(() => _isLoading = true);
    try {
      await requestPermissions();
      int numQuestions = int.tryParse(_numQuestionsController.text) ?? 0;
      String topic = _topicController.text.trim();
      String difficulty = _difficultyController.text.trim();

      if (numQuestions <= 0 || topic.isEmpty || difficulty.isEmpty) {
        _showSnackBar('Please enter valid details!', Colors.amber);
        setState(() => _isLoading = false);
        return;
      }

      String content =
          await fetchMCQsFromGemini(numQuestions, topic, difficulty);
      if (content.isEmpty || content.startsWith("Error")) {
        _showSnackBar('Failed to generate content! Try again.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      List<String> lines =
          content.split("\n").where((line) => line.trim().isNotEmpty).toList();
      List<List<String>> mcqData = [];

      for (var line in lines) {
        List<String> values = line.split(",");
        if (values.length == 6) {
          mcqData.add(values.map((e) => e.trim()).toList());
        }
      }

      if (mcqData.isEmpty) {
        _showSnackBar('Generated data is not in the correct format!', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      List<String> csvData = [];
      for (var mcq in mcqData) {
        csvData.add(mcq.map((e) => '"$e"').join(","));
      }

      Directory? downloadsDir = Directory("/storage/emulated/0/Download");
      if (!downloadsDir.existsSync()) {
        downloadsDir = await getExternalStorageDirectory();
      }
      String filePath = '${downloadsDir!.path}/MCQ_$topic.csv';
      final file = File(filePath);
      await file.writeAsString(csvData.join("\n"));

      _showSnackBar('CSV saved in Downloads: $filePath', Colors.green);
      OpenFile.open(filePath);
    } catch (e) {
      _showSnackBar('Error saving CSV: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required Color color,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
          color: Colors.white, fontSize: 14), 
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        prefixIcon: Icon(icon, color: color, size: 20),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }

  Widget _buildCompactButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        text,
        style: TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Generate MCQs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number of Questions Input
              _buildTextField(
                controller: _numQuestionsController,
                labelText: 'Number of Questions',
                icon: Icons.numbers,
                color: Colors.blue.shade200,
              ),

              const SizedBox(height: 12),

              // Topic Input
              _buildTextField(
                controller: _topicController,
                labelText: 'Enter Topic',
                icon: Icons.topic,
                color: Colors.green.shade200,
              ),

              const SizedBox(height: 12),

              // Difficulty Input
              _buildTextField(
                controller: _difficultyController,
                labelText: 'Difficulty Level',
                icon: Icons.auto_graph,
                color: Colors.purple.shade200,
              ),

              const SizedBox(height: 20),

              // Generate Button
              Center(
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.purple.shade200,
                      )
                    : _buildCompactButton(
                        text: 'Generate CSV',
                        icon: Icons.generating_tokens,
                        onPressed: generateAndSaveCSV,
                        color: Colors.green.shade700,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}