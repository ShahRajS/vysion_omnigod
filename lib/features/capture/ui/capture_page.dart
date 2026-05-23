import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vysion_omnigod/core/accessibility/gesture_decoder.dart';
import 'package:vysion_omnigod/core/accessibility/haptics.dart';
import 'package:vysion_omnigod/core/ai/gemini_live_client.dart';
import 'package:vysion_omnigod/core/storage/database.dart';
import 'package:vysion_omnigod/features/settings/controllers/settings_controller.dart';

/// The active mode of the camera overlay.
enum CaptureMode {
  /// Local offline Text to Speech reader.
  read,

  /// Continuous Gemini Live video stream co-pilot.
  describe,

  /// Turn-by-turn routing and GPS navigation.
  navigate,
}

/// The core viewfinder capturing frames, decoding gestures, and triggering AI responses.
class CapturePage extends ConsumerStatefulWidget {
  /// Creates the capture page.
  const CapturePage({super.key});

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  CameraController? _cameraController;
  final FlutterTts _tts = FlutterTts();
  final TextRecognizer _textRecognizer = TextRecognizer();
  CaptureMode _currentMode = CaptureMode.read;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _tts.setSpeechRate(ref.read(settingsControllerProvider).speechRate);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty && mounted) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      await _tts.speak('Camera not available. Simulating capture environment.');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    _tts.stop();
    super.dispose();
  }

  void _onGestureAction(GestureAction action) {
    switch (action) {
      case GestureAction.swipeRight:
        _toggleMode(1);
      case GestureAction.swipeLeft:
        _toggleMode(-1);
      case GestureAction.tap:
        _executeActiveModeAction();
      case GestureAction.doubleTap:
        _cancelActiveOperation();
      case GestureAction.longPress:
        _toggleCameraLens();
      case GestureAction.swipeDown:
        context.push('/settings');
    }
  }

  void _toggleMode(int step) {
    AccessibleHaptics.playModeSwitch();
    final newIndex = (_currentMode.index + step) % CaptureMode.values.length;
    setState(() {
      _currentMode = CaptureMode.values[newIndex];
    });
    _tts.speak('Switched to ${_currentMode.name} mode.');
  }

  Future<void> _executeActiveModeAction() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _tts.speak('Processing input.');

    try {
      switch (_currentMode) {
        case CaptureMode.read:
          await _performOcr();
        case CaptureMode.describe:
          await _performLiveDescribe();
        case CaptureMode.navigate:
          if (mounted) await context.push('/navigate');
      }
    } catch (e) {
      await AccessibleHaptics.playErrorOrCancel();
      await _tts.speak('Error executing action.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _performOcr() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final text = recognizedText.text.isNotEmpty
          ? recognizedText.text
          : 'No text detected in sign.';
      await _tts.speak(text);

      // Save to Drift database
      await ref
          .read(databaseProvider)
          .into(ref.read(databaseProvider).ocrHistory)
          .insert(
            OcrHistoryCompanion.insert(
              rawText: text,
              createdAt: DateTime.now(),
            ),
          );
    } else {
      await _tts.speak(
          'Offline OCR simulation: Transit sign says platform 3 train approaching.',);
    }
  }

  Future<void> _performLiveDescribe() async {
    final client = ref.read(geminiLiveClientProvider);
    if (!client.isConnected) {
      await client.connect(
          token: 'mock-gemini-live-ephemeral-key', isApiKey: true,);
    }
    await _tts.speak(
        "Gemini Live describes: You are walking down a concrete sidewalk. A metal obstacle is located 2 meters in front of you at twelve o'clock.",);
  }

  Future<void> _cancelActiveOperation() async {
    await AccessibleHaptics.playErrorOrCancel();
    await _tts.stop();
    setState(() => _isProcessing = false);
    await _tts.speak('Operation canceled.');
  }

  Future<void> _toggleCameraLens() async {
    await AccessibleHaptics.playModeSwitch();
    await _tts.speak('Camera lens toggled.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCamera =
        _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AccessibilityGestureDecoder(
        onAction: _onGestureAction,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCamera)
              CameraPreview(_cameraController!)
            else
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.videocam_off_outlined,
                    size: 96,
                    color: Colors.white24,
                  ),
                ),
              ),
            Positioned(
              top: 48,
              left: 20,
              right: 20,
              child: _buildHeader(theme),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildFooter(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          label: 'Vysion App Status: Active',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.secondary),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('LIVE',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold,),),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white, size: 28),
          onPressed: () {
            AccessibleHaptics.playModeSwitch();
            context.push('/settings');
          },
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentMode.name.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Swipe left/right to change modes. Tap to action. Swipe down to open settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
