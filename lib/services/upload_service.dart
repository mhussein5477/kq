import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// Service for handling profile picture and document uploads
class UploadService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from gallery
  static Future<UploadFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        return UploadFile(
          fileName: image.name,
          fileBytes: bytes,
          filePath: image.path,
          fileExtension: image.path.split('.').last,
          fileType: UploadFileType.image,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  static Future<UploadFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        return UploadFile(
          fileName: image.name,
          fileBytes: bytes,
          filePath: image.path,
          fileExtension: image.path.split('.').last,
          fileType: UploadFileType.image,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick document file (PDF, JPG, PNG)
  static Future<UploadFile?> pickDocument({
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  }) async {
    try {
      // Note: For mobile, we can only filter by general type (image, video, etc.)
      // File extension filtering happens after selection
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Get file extension
        final extension = file.extension?.toLowerCase() ?? '';
        
        // Validate extension
        if (!allowedExtensions.contains(extension)) {
          debugPrint('Invalid file type: $extension. Allowed: $allowedExtensions');
          throw Exception('Invalid file type. Please select: ${allowedExtensions.join(", ")}');
        }
        
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = file.bytes;
        } else {
          if (file.path != null) {
            bytes = await File(file.path!).readAsBytes();
          }
        }

        if (bytes == null) {
          throw Exception('Could not read file bytes');
        }

        return UploadFile(
          fileName: file.name,
          fileBytes: bytes,
          filePath: file.path,
          fileExtension: extension,
          fileType: UploadFileType.document,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error picking document: $e');
      return null;
    }
  }

  /// Show image source selection dialog
  static Future<UploadFile?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<UploadFile>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFFE31E24)),
                  title: const Text('Gallery'),
                  onTap: () async {
                    final file = await pickImageFromGallery();
                    if (context.mounted) {
                      Navigator.pop(context, file);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFFE31E24)),
                  title: const Text('Camera'),
                  onTap: () async {
                    final file = await pickImageFromCamera();
                    if (context.mounted) {
                      Navigator.pop(context, file);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Enum for upload file types
enum UploadFileType {
  image,
  document,
}

/// Data class for uploaded files
class UploadFile {
  final String fileName;
  final Uint8List fileBytes;
  final String? filePath;
  final String fileExtension;
  final UploadFileType fileType;

  UploadFile({
    required this.fileName,
    required this.fileBytes,
    this.filePath,
    required this.fileExtension,
    required this.fileType,
  });

  /// Get file size in MB
  double get fileSizeInMB => fileBytes.length / (1024 * 1024);

  /// Convert to base64
  String toBase64() => base64Encode(fileBytes);

  /// Check if file size is valid (default 5MB max)
  bool isValidSize({double maxSizeMB = 5.0}) {
    return fileSizeInMB <= maxSizeMB;
  }

  /// Check if file extension is valid
  bool isValidExtension(List<String> allowedExtensions) {
    return allowedExtensions.contains(fileExtension.toLowerCase());
  }

  /// Validate file
  bool isValid({
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    double maxSizeMB = 5.0,
  }) {
    return isValidSize(maxSizeMB: maxSizeMB) && 
           isValidExtension(allowedExtensions);
  }

  /// Get validation error message
  String? getValidationError({
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    double maxSizeMB = 5.0,
  }) {
    if (!isValidSize(maxSizeMB: maxSizeMB)) {
      return 'File size exceeds ${maxSizeMB}MB limit. Current size: ${fileSizeInMB.toStringAsFixed(2)}MB';
    }
    if (!isValidExtension(allowedExtensions)) {
      return 'Invalid file type. Allowed: ${allowedExtensions.join(", ")}';
    }
    return null;
  }
}