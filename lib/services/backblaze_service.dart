import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackblazeService {
  final Dio _dio = Dio();
  late String _authToken;
  late String _apiUrl;



  Future<void> _authenticate() async {
    final response = await _dio.post(
      'https://api.backblazeb2.com/b2api/v2/b2_authorize_account',
      options: Options(
        headers: {
          'Authorization': 'Basic ${se64Encode(
            utf8.encode('${dotenv.env['B2_KEY_ID']}:${dotenv.env['B2_APPLICATION_KEY']}'),
          )}',
        },
      ),
    );

    _authToken = response.data['authorizationToken'];
    _apiUrl = response.data['apiUrl'];
  }

  Future<String> uploadVideo(File file) async {
    await _authenticate();

    // Get upload URL
    final uploadUrlResponse = await _dio.post(
      '$_apiUrl/b2api/v2/b2_get_upload_url',
      data: {'bucketId': dotenv.env['B2_BUCKET_NAME']},
      options: Options(headers: {'Authorization': _authToken}),
    );

    // Upload file
    final uploadResponse = await _dio.post(
      uploadUrlResponse.data['uploadUrl'],
      data: file.openRead(),
      options: Options(
        headers: {
          'Authorization': uploadUrlResponse.data['authorizationToken'],
          'Content-Type': 'b2/x-auto',
          'X-Bz-File-Name': 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4',
          'X-Bz-Content-Sha1': await _calculateSha1(file),
        },
      ),
    );

    return '${dotenv.env['B2_ENDPOINT']}/file/${dotenv.env['B2_BUCKET_NAME']}/${uploadResponse.data['fileName']}';
  }

  Future<String> _calculateSha1(File file) async {
    // Implement SHA1 calculation
    return 'do_not_verify'; // For simplicity in example
  }

  se64Encode(Uint8List encode) {}
}

