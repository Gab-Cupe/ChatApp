import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;

class ImageService {
  static const String _apiKey = 'e2d9e1355d9d0069772cf65e032b86e0';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  static Future<String?> uploadImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      return _uploadImageBytes(bytes);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  static Future<String?> uploadImageFromBytes(Uint8List bytes) async {
    return _uploadImageBytes(bytes);
  }

  static Future<String?> _uploadImageBytes(Uint8List bytes) async {
    try {
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('$_uploadUrl?key=$_apiKey'),
        body: {
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']['url'];
      } else {
        debugPrint('Error uploading image: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}