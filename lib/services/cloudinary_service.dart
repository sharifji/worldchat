// cloudinary_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String _cloudName = 'dyix7swr2';
  static const String _apiKey = '813319835591272';
  static const String _apiSecret = 'a0JqObGYKZ16uCbznA7nOLP3yvU'; // REPLACE WITH YOUR SECRET
  static const String _uploadPreset = 'General';
  // This should exactly match:
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/dyix7swr2/upload';
 // static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/dylx7swr2/upload';
  //static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/upload';

  Future<String> uploadFile(File file, {String? folder, bool isVideo = false, required String resourceType}) async {
    try {
      // Prepare all parameters that need to be signed
      final params = {
        'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        'upload_preset': _uploadPreset,
        if (folder != null) 'folder': folder,
      };

      // Create the request
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields.addAll(params)
        ..fields['api_key'] = _apiKey
        ..fields['signature'] = _calculateSignature(params);

      // Prepare the file
      final mimeType = lookupMimeType(file.path);
      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: basename(file.path),
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );

      request.files.add(multipartFile);

      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String;
      } else {
        throw 'Upload failed with status ${response.statusCode}: $responseData';
      }
    } catch (e) {
      throw 'Failed to upload file: $e';
    }
  }

  String _calculateSignature(Map<String, String> params) {
    // Sort parameters alphabetically
    final sortedKeys = params.keys.toList()..sort();

    // Create the signature payload string
    final signaturePayload = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Combine with API secret and hash
    final fullString = '$signaturePayload$_apiSecret';
    final bytes = utf8.encode(fullString);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  Future<String> uploadImage(File imageFile, {String? folder}) async {
    return uploadFile(imageFile, folder: folder ?? 'profile_pictures', resourceType: '');
  }

  Future<String> uploadVideo(
      File videoFile, {
        String? folder,
        required void Function(double progress) onProgress,
      }) async {
    final length = await videoFile.length();
    final stream = videoFile.openRead();
    var total = 0;

    final transformedStream = stream.transform<List<int>>(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) {
          total += data.length;
          onProgress(total / length);
          sink.add(data);
        },
      ),
    );

    final params = {
      'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      'upload_preset': _uploadPreset,
      'folder': folder ?? 'videos',
    };

    final uri = Uri.parse(_uploadUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields.addAll(params)
      ..fields['api_key'] = _apiKey
      ..fields['signature'] = _calculateSignature(params);

    final multipartFile = http.MultipartFile(
      'file',
      transformedStream,
      length,
      filename: basename(videoFile.path),
      contentType: MediaType('video', '*'),
    );

    request.files.add(multipartFile);

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return jsonResponse['secure_url'] as String;
    } else {
      throw 'Upload failed with status ${response.statusCode}: $responseData';
    }
  }
}