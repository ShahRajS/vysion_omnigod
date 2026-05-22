import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vysion_omnigod/app/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Client to communicate with Gemini's Multimodal Live API over WebSockets.
class GeminiLiveClient {
  /// Creates a Gemini Live Client.
  GeminiLiveClient({required this.config});

  /// The application configuration.
  final AppConfig config;

  WebSocketChannel? _channel;
  bool _isConnected = false;

  final _textController = StreamController<String>.broadcast();
  final _audioController = StreamController<List<int>>.broadcast();

  /// Stream of textual description segments received from the model.
  Stream<String> get textStream => _textController.stream;

  /// Stream of PCM audio output bytes (24kHz) received from the model.
  Stream<List<int>> get audioStream => _audioController.stream;

  /// Checks if the client is connected.
  bool get isConnected => _isConnected;

  /// Establishes the WebSocket connection using an OAuth token or API key.
  Future<void> connect({
    required String token,
    bool isApiKey = false,
  }) async {
    if (_isConnected) {
      return;
    }

    final queryParam = isApiKey ? 'key=$token' : 'access_token=$token';
    final uri = Uri.parse(
      'wss://${config.geminiApiHost}/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?$queryParam',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      // Start listening to the stream
      _channel!.stream.listen(
        _onMessageReceived,
        onError: _onConnectionError,
        onDone: _onConnectionClosed,
      );

      // Send initial Setup message
      await _sendSetup();
      developer.log('Gemini Live WebSocket connected successfully.');
    } catch (e) {
      _isConnected = false;
      developer.log('Failed to connect to Gemini Live WebSocket', error: e);
      rethrow;
    }
  }

  /// Sends the initial configuration to the Gemini Live server.
  Future<void> _sendSetup() async {
    final setupMsg = {
      'setup': {
        'model':
            'models/gemini-2.0-flash-exp', // Or gemini-2.5-flash-preview when available
        'generationConfig': {
          'responseModalities': ['AUDIO', 'TEXT'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': 'Aoede', // Concierge, Aoede, Charon, Fenrir, Kore
              },
            },
          },
        },
        'systemInstruction': {
          'parts': [
            {
              'text': 'You are Vysion, a calm, concise navigation companion for a blind user. '
                  "Never use visual deixis like 'this' or 'over there'; describe positions "
                  'in clock-face directions and meter distances. Warn about hazards in <300ms. '
                  'Keep descriptions concise.',
            }
          ],
        },
      },
    };
    _channel?.sink.add(jsonEncode(setupMsg));
  }

  /// Sends a base64 encoded JPEG video frame to the Live session.
  void sendVideoFrame(List<int> jpegBytes) {
    if (!_isConnected || _channel == null) return;

    final base64Frame = base64Encode(jpegBytes);
    final inputMsg = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'image/jpeg',
            'data': base64Frame,
          }
        ],
      },
    };
    _channel!.sink.add(jsonEncode(inputMsg));
  }

  /// Sends a chunk of PCM audio input to the Live session.
  void sendAudioFrame(List<int> pcmBytes) {
    if (!_isConnected || _channel == null) return;

    final base64Audio = base64Encode(pcmBytes);
    final inputMsg = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'audio/pcm;rate=16000',
            'data': base64Audio,
          }
        ],
      },
    };
    _channel!.sink.add(jsonEncode(inputMsg));
  }

  /// Closes the active session.
  Future<void> disconnect() async {
    if (!_isConnected) return;
    await _channel?.sink.close();
    _isConnected = false;
    developer.log('Gemini Live WebSocket disconnected.');
  }

  void _onMessageReceived(dynamic message) {
    try {
      final data = jsonDecode(message.toString()) as Map<String, dynamic>;
      if (data.containsKey('serverContent')) {
        final serverContent = data['serverContent'] as Map<String, dynamic>;
        if (serverContent.containsKey('modelTurn')) {
          final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>;
          final parts = modelTurn['parts'] as List<dynamic>? ?? [];

          for (final part in parts) {
            final partMap = part as Map<String, dynamic>;
            if (partMap.containsKey('text')) {
              _textController.add(partMap['text'] as String);
            } else if (partMap.containsKey('inlineData')) {
              final inlineData = partMap['inlineData'] as Map<String, dynamic>;
              final mimeType = inlineData['mimeType'] as String;
              if (mimeType.startsWith('audio/pcm')) {
                final audioData = base64Decode(inlineData['data'] as String);
                _audioController.add(audioData);
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error parsing Gemini Live WebSocket message', error: e);
    }
  }

  void _onConnectionError(dynamic error) {
    developer.log('Gemini Live WebSocket error occurred', error: error);
    _isConnected = false;
  }

  void _onConnectionClosed() {
    developer.log('Gemini Live WebSocket stream connection closed.');
    _isConnected = false;
  }
}

/// Provider for the GeminiLiveClient instance.
final geminiLiveClientProvider = Provider<GeminiLiveClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return GeminiLiveClient(config: config);
});
