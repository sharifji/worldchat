import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart' as open_file;
import 'package:pdfx/pdfx.dart';

class FileProcessingService {
  final FlutterTts _tts = FlutterTts();

  Future<String> extractTextFromFile(File file, String fileName) async {
    final extension = fileName.split('.').last.toLowerCase();

    try {
      if (extension == 'pdf') {
        return await _extractTextFromPDF(file);
      } else if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        return await _extractTextFromImage(file);
      } else if (['txt', 'md'].contains(extension)) {
        return await file.readAsString();
      } else if (['doc', 'docx'].contains(extension)) {
        return await _extractTextFromWord(file);
      } else {
        return 'Unsupported file type: $extension';
      }
    } catch (e) {
      return 'Error processing file: $e';
    }
  }

  Future<String> _extractTextFromPDF(File file) async {
    try {
      final document = await PdfDocument.openFile(file.path);
      String fullText = '';

      // Extract text from all pages
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
       // final pageText = await page.text;
      //  fullText += '${pageText.text}\n\n';
        await page.close();
      }

      await document.close();
      return fullText.isNotEmpty ? fullText : 'No text found in PDF';
    } catch (e) {
      return 'PDF processing error: $e';
    }
  }

  Future<String> _extractTextFromImage(File imageFile) async {
    try {
      // Placeholder for actual OCR implementation
      return 'Image content analysis would go here. [SEARCH:${_generateSearchQueryFromImage(imageFile)}]';
    } catch (e) {
      return 'Image processing error: $e';
    }
  }

  Future<String> _extractTextFromWord(File file) async {
    try {
      // Placeholder for Word document processing
      return 'Word document content would be extracted here. [SEARCH:document content]';
    } catch (e) {
      return 'Word document processing error: $e';
    }
  }

  String _generateSearchQueryFromImage(File imageFile) {
    // Placeholder for image analysis
    return 'objects in image';
  }

  Future<File> saveFileToLocalStorage(File file, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final savedFile = File('${appDir.path}/$fileName');
      await file.copy(savedFile.path);
      return savedFile;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  Future<void> speakFileContent(String content) async {
    await _tts.speak(content);
  }

  Future<void> openFile(String? filePath) async {
    if (filePath == null) return;
    try {
      await open_file.OpenFile.open(filePath);
    } catch (e) {
      throw Exception('Failed to open file: $e');
    }
  }

  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('File picking failed: $e');
    }
  }

  Future<Uint8List?> compressImage(File imageFile, {int quality = 80}) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  static String getFileNameWithoutExtension(String fileName) {
    return fileName.replaceAll(RegExp(r'\.[^\.]+$'), '');
  }
}

