// lib/services/cloudinary_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'n7l0th9e';
  static const String uploadPreset = 'canteen_images';

  /// Uploads an image file to Cloudinary using unsigned upload.
  /// Returns the secure HTTPS URL of the uploaded image.
  static Future<String> uploadImage(
    XFile imageFile, {
    String folder = 'menu_items',
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary is not configured yet. Please set your "cloudName" and "uploadPreset" in lib/services/cloudinary_service.dart',
      );
    }

    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add Cloudinary preset and optional folder
      request.fields['upload_preset'] = uploadPreset;
      if (folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      // Read file bytes (compatible with Web, Android, iOS, Windows)
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name.isNotEmpty ? imageFile.name : 'upload.png',
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? secureUrl = responseData['secure_url'];
        if (secureUrl != null && secureUrl.isNotEmpty) {
          debugPrint('Cloudinary upload success: $secureUrl');
          return secureUrl;
        } else {
          throw Exception('Upload succeeded but no secure_url returned.');
        }
      } else {
        String errorMessage = 'Upload failed with status ${response.statusCode}';
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }
}

