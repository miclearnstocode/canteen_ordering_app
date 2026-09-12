import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ImagePickerHelper {
  static Future<XFile?> pickImage() async {
    try {
      if (kIsWeb) {
        // For web, use file picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true, // Required for web
        );
        
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          
          if (file.bytes != null) {
            // Get file extension
            String extension = file.extension ?? 'jpg';
            
            // Determine mime type
            String mimeType;
            switch (extension.toLowerCase()) {
              case 'png':
                mimeType = 'image/png';
                break;
              case 'gif':
                mimeType = 'image/gif';
                break;
              case 'webp':
                mimeType = 'image/webp';
                break;
              case 'jpg':
              case 'jpeg':
              default:
                mimeType = 'image/jpeg';
                break;
            }
            
            // Create XFile from bytes with proper mime type
            return XFile.fromData(
              file.bytes!,
              name: file.name,
              mimeType: mimeType,
            );
          }
        }
        return null;
      } else {
        // Mobile: Use image_picker
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        return image;
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // For camera on mobile
  static Future<XFile?> pickImageFromCamera() async {
    if (kIsWeb) {
      // Web doesn't support camera well, fallback to file picker
      return pickImage();
    }
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    return image;
  }
}