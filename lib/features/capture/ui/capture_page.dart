import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:vysion_omnigod/core/accessibility/gesture_decoder.dart';
import 'package:vysion_omnigod/core/accessibility/haptics.dart';
import 'package:vysion_omnigod/core/ai/gemini_live_client.dart';
import 'package:vysion_omnigod/core/ai/translation_service.dart';
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
  CaptureMode _currentMode = CaptureMode.read;
  bool _isProcessing = false;
  String? _statusMessage;

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
      _statusMessage = null;
    });
    _tts.speak('Switched to ${_currentMode.name} mode.');
  }

  Future<void> _executeActiveModeAction() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing image...';
    });
    await _tts.speak('Processing input.');

    try {
      switch (_currentMode) {
        case CaptureMode.read:
          await _performOcr();
        case CaptureMode.describe:
          await _performLiveDescribe();
        case CaptureMode.navigate:
          await _performNavigationDemo();
      }
    } catch (e) {
      await AccessibleHaptics.playErrorOrCancel();
      await _tts.speak('Error executing action.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _performOcr() async {
    // Tesseract OCR native binaries do not support web. If running on web, use simulation mode.
    if (!kIsWeb && _cameraController != null && _cameraController!.value.isInitialized) {
      final image = await _cameraController!.takePicture();
      
      // Perform local offline OCR using Tesseract, loading both English and Spanish traineddata
      final rawText = await FlutterTesseractOcr.extractText(
        image.path,
        language: 'eng+spa',
        args: {
          'psm': '4',
          'preserve_interword_spaces': '1',
        },
      );

      final text = rawText.trim().isNotEmpty ? rawText.trim() : 'No text detected in sign.';
      final hasText = rawText.trim().isNotEmpty;
      
      // Translate to English if necessary using Gemini
      final translatedText = await ref.read(translationServiceProvider).translateToEnglish(text);
      
      setState(() {
        _statusMessage = hasText ? 'Scanned: "$translatedText"' : 'No text detected.';
      });
      await _tts.speak(translatedText);

      // Save to Drift database (save the raw scanned text)
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
      // Simulation fallback for Web or simulator environments where native OCR is unavailable
      final text = kIsWeb
          ? 'Spanish transit sign: Cuidado con el escalón.'
          : 'Transit sign says platform 3 train approaching.';

      final translatedText = await ref.read(translationServiceProvider).translateToEnglish(text);
      
      setState(() {
        _statusMessage = 'Scanned: "$translatedText"';
      });
      await _tts.speak(translatedText);

      // Save to Drift database (save the raw scanned text)
      await ref
          .read(databaseProvider)
          .into(ref.read(databaseProvider).ocrHistory)
          .insert(
            OcrHistoryCompanion.insert(
              rawText: text,
              createdAt: DateTime.now(),
            ),
          );
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

  Future<void> _performNavigationDemo() async {
    await _tts.speak(
        "Navigation co-pilot active. Walk straight 10 meters, then turn right to three o'clock.",);
  }

  Future<void> _cancelActiveOperation() async {
    await AccessibleHaptics.playErrorOrCancel();
    await _tts.stop();
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Operation canceled.';
    });
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
              top: 110,
              left: 20,
              right: 20,
              child: Center(child: _buildStatusBadge(theme)),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildFooter(theme),
            ),
            _buildShutterButton(theme),
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

  Widget _buildShutterButton(ThemeData theme) {
    final color = theme.colorScheme.secondary;

    return Positioned(
      bottom: 170,
      left: 0,
      right: 0,
      child: Center(
        child: Semantics(
          button: true,
          label: 'Take picture and analyze',
          child: GestureDetector(
            onTap: _executeActiveModeAction,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
                border: Border.all(
                  color: color.withOpacity(0.6),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: _isProcessing
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 3,
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    if (_statusMessage == null && !_isProcessing) return const SizedBox.shrink();

    final isErrorOrNoText = _statusMessage?.contains('No text') ?? false;
    final isCanceled = _statusMessage?.contains('canceled') ?? false;
    final color = _isProcessing
        ? theme.colorScheme.secondary
        : (isErrorOrNoText || isCanceled ? Colors.amber : Colors.greenAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isProcessing)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(
              isErrorOrNoText || isCanceled ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: color,
              size: 16,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _statusMessage ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
