import 'dart:async';
import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vysion_omnigod/core/ai/gemini_live_client.dart';

enum GeminiLiveState { disconnected, connecting, listening, speaking, error }

class GeminiLiveService {
  GeminiLiveService({required this.client});

  final GeminiLiveClient client;
  final _stateNotifier = ValueNotifier<GeminiLiveState>(
    GeminiLiveState.disconnected,
  );
  final _tts = FlutterTts();

  Timer? _frameTimer;
  CameraController? _camera;
  StreamSubscription<String>? _textSub;
  bool _framesPaused = false;
  int _reconnectAttempts = 0;
  static const _maxReconnects = 3;

  ValueNotifier<GeminiLiveState> get stateNotifier => _stateNotifier;
  GeminiLiveState get state => _stateNotifier.value;

  Future<void> connect(CameraController camera) async {
    _camera = camera;
    _stateNotifier.value = GeminiLiveState.connecting;
    _reconnectAttempts = 0;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);

    _tts.setCompletionHandler(() {
      if (_stateNotifier.value == GeminiLiveState.speaking) {
        _stateNotifier.value = GeminiLiveState.listening;
        resumeFrames();
      }
    });

    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final apiKey = client.config.geminiApiKey;
      await client.connect(token: apiKey, isApiKey: true);

      _stateNotifier.value = GeminiLiveState.listening;
      _reconnectAttempts = 0;

      _textSub?.cancel();
      _textSub = client.textStream.listen(_onTextReceived);

      _startFrameCapture();
    } catch (e) {
      developer.log('GeminiLiveService connect failed', error: e);
      await _handleDisconnect();
    }
  }

  void _onTextReceived(String text) {
    if (text.trim().isEmpty) return;

    _stateNotifier.value = GeminiLiveState.speaking;
    pauseFrames();
    _tts.speak(text);
  }

  void _startFrameCapture() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _captureAndSendFrame();
    });
  }

  Future<void> _captureAndSendFrame() async {
    if (_framesPaused || _camera == null || !_camera!.value.isInitialized) {
      return;
    }
    if (!client.isConnected) return;

    try {
      final file = await _camera!.takePicture();
      final bytes = await file.readAsBytes();
      client.sendVideoFrame(bytes);
    } catch (e) {
      developer.log('Frame capture failed', error: e);
    }
  }

  Future<void> _handleDisconnect() async {
    _reconnectAttempts++;
    if (_reconnectAttempts <= _maxReconnects) {
      _stateNotifier.value = GeminiLiveState.connecting;
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_stateNotifier.value != GeminiLiveState.disconnected) {
        await _doConnect();
      }
    } else {
      _stateNotifier.value = GeminiLiveState.error;
    }
  }

  void pauseFrames() {
    _framesPaused = true;
  }

  void resumeFrames() {
    _framesPaused = false;
  }

  Future<void> disconnect() async {
    _stateNotifier.value = GeminiLiveState.disconnected;
    _frameTimer?.cancel();
    _frameTimer = null;
    _textSub?.cancel();
    _textSub = null;
    await _tts.stop();
    await client.disconnect();
    _camera = null;
  }

  void dispose() {
    disconnect();
    _stateNotifier.dispose();
  }
}

final geminiLiveServiceProvider = Provider<GeminiLiveService>((ref) {
  final client = ref.watch(geminiLiveClientProvider);
  final service = GeminiLiveService(client: client);
  ref.onDispose(service.dispose);
  return service;
});
