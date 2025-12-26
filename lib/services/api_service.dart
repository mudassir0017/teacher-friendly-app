import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Replace with your actual API endpoint
  static const String baseUrl = 'https://api.example.com';

  Future<bool> uploadAssignment({
    required String title,
    required String description,
    required String className,
    required String subject,
    File? file,
  }) async {
    var uri = Uri.parse('$baseUrl/assignments/upload');
    var request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['class'] = className;
    request.fields['subject'] = subject;

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'assignment_file',
          file.path,
        ),
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Upload failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading assignment: $e');
      return false;
    }
  }
}
