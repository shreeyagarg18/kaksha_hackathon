import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ImageDisplayScreen.dart';

class homeStudent extends StatefulWidget {
  const homeStudent({super.key});

  @override
  _homeStudentstate createState() => _homeStudentstate();
}

class _homeStudentstate extends State<homeStudent> {
  Future<void> uploadPDF() async {
    try {
      // Pick a PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file selected')),
        );
        return;
      }

      // Ensure the file path is valid
      String? filePath = result.files.single.path;
      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid file path')),
        );
        return;
      }

      File file = File(filePath);

      // Convert PDF to images
      List<String> imagePaths = await _convertPdfToImages(file);

      // Extract text using Google Vision
      String extractedText = await extractTextFromImages(imagePaths);

      // Send the extracted text to Gemini for analysis
      String geminiResponse = await sendToGeminiAPI(extractedText);

      // Navigate to TextDisplayScreen and show Gemini analysis
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ImageDisplayScreen(extractedText: geminiResponse),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<List<String>> _convertPdfToImages(File pdfFile) async {
    final pdfDocument = await PdfDocument.openFile(pdfFile.path);
    final tempDir = await getTemporaryDirectory();
    List<String> imagePaths = [];

    for (int i = 1; i <= pdfDocument.pageCount; i++) {
      final page = await pdfDocument.getPage(i);
      final pdfPageImage = await page.render(
        width: (page.width * 2).toInt(),
        height: (page.height * 2).toInt(),
      );

      final image = await pdfPageImage.createImageIfNotAvailable();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final imagePath = '${tempDir.path}/page_$i.png';
      final file = File(imagePath);
      await file.writeAsBytes(buffer);
      imagePaths.add(imagePath);

      // Dispose of the image to free up memory
      image.dispose();
    }
    return imagePaths;
  }

  Future<String> extractTextFromImages(List<String> imagePaths) async {
    String extractedText = "";
    for (String imagePath in imagePaths) {
      File imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final payload = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "DOCUMENT_TEXT_DETECTION"}
            ]
          }
        ]
      });

      final response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyAiH173s0PPDFWNtJpcuzPLdu3i_0mi8Ao'),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String text =
            responseBody["responses"][0]["fullTextAnnotation"]["text"];
        extractedText += text + "\n\n";
        print("API Response: ${response.body}");
      } else {
        print("Failed to extract text from $imagePath");
        print("API Response: ${response.body}");
      }
    }
    return extractedText;
  }

  Future<String> sendToGeminiAPI(String extractedText) async {
    const apiKey =
        'AIzaSyAiH173s0PPDFWNtJpcuzPLdu3i_0mi8Ao'; // Replace with actual API key
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    String prompt = '''
    The extracted text from the PDF is:
    $extractedText
    Please analyze this text and provide a professional and user-friendly summary. Format the output in a manner that is easy to read and should not exceed 100 words.
    ''';

    final requestPayload = {
      "contents": [
        {
          "parts": [
            {
              "text": prompt,
            }
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
        if (jsonResponse['candidates'] != null &&
            jsonResponse['candidates'].isNotEmpty) {
          final candidate =
              jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          return candidate;
        } else {
          return 'No response from Gemini API.';
        }
      } else {
        print("Failed to get Gemini response");
        return 'Error: ${response.statusCode}, Response Body: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: uploadPDF,
          child: Text('Upload PDF'),
        ),
      ),
    );
  }
}
