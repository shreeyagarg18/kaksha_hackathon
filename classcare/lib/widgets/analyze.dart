import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';

class PDFUploadService {
  Future<String> extractTextFromPDF(String fileUrl) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/downloaded_file.pdf';

        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        List<String> imagePaths = await _convertPdfToImages(file);
        String extractedText = await extractTextFromImages(imagePaths);

        return extractedText;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error extracting text from PDF: $e');
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

      final response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyAiH173s0PPDFWNtJpcuzPLdu3i_0mi8Ao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "DOCUMENT_TEXT_DETECTION"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String text =
            responseBody["responses"][0]["fullTextAnnotation"]["text"];
        extractedText += "$text\n\n";
      }
    }
    return extractedText;
  }

  Future<String> sendToGeminiAPI(
      String assignmentText, String rubricText, String studentText) async {
    const apiKey = 'AIzaSyAiH173s0PPDFWNtJpcuzPLdu3i_0mi8Ao';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    String prompt = '''
    Assignment Text:
    $assignmentText

    Rubric Text:
    $rubricText

    Student Submission Text:
    $studentText

    Analyze the student's submission based on the assignment instructions and rubric. For each question, understand the question from the "assignmentText" , get the correct answer from the rubrics from "rubricText", tally with answer of the student from the "studentText". Check how much similar the answer is to the rubrics, look for keywords match with the student's submission for that question. If the final answer is wrong, give step marks. Award full marks when it is completely match with the rubrics. Consider each question to be of 10 marks each(there might be sub questions of different denominations like 3+7, 5+5, etc). If the question is attempted give atleast 2 marks.  
    Give the response in this json format.
    "student":{
    total marks:
    "Q1":{
    "Marks":
    "Feedback":(only the topic names, where the student is stropng or weak)
    }
    "Q2":{
    "Marks":
    "Feedback":
    }
    }
    Strictly follow the JSON
    ''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null &&
            jsonResponse['candidates'].isNotEmpty) {
          return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      return 'Error analyzing submission';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
