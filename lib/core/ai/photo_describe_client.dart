import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:vysion_omnigod/app/config/app_config.dart';

/// Result from the photo describe backend.
class PhotoDescribeResult {
  /// The text description returned by Gemini.
  final String description;

  const PhotoDescribeResult({
    required this.description,
  });
}

/// Client that sends raw image bytes to the backend photo describe pipeline.
class PhotoDescribeClient {
  PhotoDescribeClient({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final AppConfig config;
  final http.Client _client;

  Future<PhotoDescribeResult> describePhoto({
    required Uint8List imageBytes,
    String? authToken,
  }) async {
    final url = Uri.parse('${config.backendBaseUrl}/v1/photo/describe');
    final headers = <String, String>{
      'Content-Type': 'image/jpeg',
      'Accept': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final response = await _client.post(url, headers: headers, body: imageBytes);

    if (response.statusCode != 200) {
      throw Exception(
        'Photo describe request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final description = data['description'] as String? ?? '';
    return PhotoDescribeResult(
      description: description,
    );
  }
}
