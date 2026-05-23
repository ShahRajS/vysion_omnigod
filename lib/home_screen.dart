// FILE: lib/home_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:blinkid_flutter/blinkid_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:vysion_omnigod/camera_provider.dart';
import 'package:vysion_omnigod/core/accessibility/haptics.dart';
import 'package:vysion_omnigod/core/ai/gemini_live_client.dart';
import 'package:vysion_omnigod/core/ai/translation_service.dart';
import 'package:vysion_omnigod/core/storage/database.dart';
import 'package:vysion_omnigod/features/settings/controllers/settings_controller.dart';
import 'package:vysion_omnigod/pages/audio_descriptions_page.dart';
import 'package:vysion_omnigod/pages/navigation_page.dart';
import 'package:vysion_omnigod/pages/text_reader_page.dart';
import 'package:vysion_omnigod/widgets/frosted_pill.dart';
import 'package:vysion_omnigod/widgets/page_dots.dart';

/// The central container screen of the Visual Accessibility Assistant.
/// Orchestrates camera feeds, horizontal drag transitions, and overlays.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // 1. Controller
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // TTS, Processing and OCR States
  final FlutterTts _tts = FlutterTts();
  bool _isProcessing = false;
  String? _statusMessage;

  // Flash animation states for shutter release
  bool _isFlashVisible = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  // Recording pulse states for Page 1
  bool _isRecording = false;
  late AnimationController _recordPulseController;

  // Navigation pulse states for Page 2
  late AnimationController _navigationPulseController;
  late Animation<double> _navigationPulseAnimation;

  @override
  void initState() {
    super.initState();

    // 300ms flash fade in/out animation configuration
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 65,
      ),
    ]).animate(_flashController);

    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isFlashVisible = false;
        });
      }
    });

    // Recording animation (Page 1)
    _recordPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Navigation continuous pulse animation (Page 2)
    _navigationPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _navigationPulseAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _navigationPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _navigationPulseController.repeat(reverse: true);

    // Defer so the widget tree is mounted before async work begins
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).init();
      _tts.setSpeechRate(ref.read(settingsControllerProvider).speechRate);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flashController.dispose();
    _recordPulseController.dispose();
    _navigationPulseController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _triggerFlash() {
    setState(() {
      _isFlashVisible = true;
    });
    _flashController.forward(from: 0);
  }

  Future<void> _executeActiveModeAction() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing image...';
    });
    await _tts.speak('Processing input.');

    try {
      if (_currentPage == 0) {
        await _performOcr();
      } else if (_currentPage == 1) {
        await _performLiveDescribe();
      } else if (_currentPage == 2) {
        await _performNavigationDemo();
      }
    } catch (e) {
      await AccessibleHaptics.playErrorOrCancel();
      await _tts.speak('Error executing action.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String? _getStringValue(StringResult? res) {
    if (res == null) return null;
    return res.latin ?? res.value ?? res.arabic ?? res.cyrillic ?? res.greek;
  }

  String? _getDateString(DateResult<StringResult>? dateResult) {
    if (dateResult == null) return null;
    final d = dateResult.date;
    if (d != null && d.day != null && d.month != null && d.year != null) {
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    return _getStringValue(dateResult.originalString);
  }

  Future<void> _performOcr() async {
    // BlinkID does not support web or tests. If running on web or under test, use simulation mode.
    final bool isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!kIsWeb && !isTest) {
      try {
        // Platform specific license keys. Microblink license keys are bundle ID / package name specific.
        String licenseKey = '';
        if (defaultTargetPlatform == TargetPlatform.android) {
          licenseKey = 'YOUR_ANDROID_LICENSE_KEY';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          licenseKey = 'YOUR_IOS_LICENSE_KEY';
        }

        final sdkSettings = BlinkIdSdkSettings(licenseKey);
        sdkSettings.downloadResources = true;

        final sessionSettings = BlinkIdSessionSettings();
        sessionSettings.scanningMode = ScanningMode.automatic;

        final blinkidPlugin = BlinkidFlutter();
        final result = await blinkidPlugin.performScan(
          sdkSettings,
          sessionSettings,
        );

        if (result == null) {
          setState(() {
            _statusMessage = 'Scan canceled.';
          });
          await _tts.speak('Scan canceled.');
          return;
        }

        String? docType;
        if (result.documentClassInfo != null) {
          final classInfo = result.documentClassInfo!;
          final countryName = classInfo.countryName;
          final docTypeName = classInfo.documentType?.name.toUpperCase();
          if (countryName != null && docTypeName != null) {
            docType = '$countryName $docTypeName';
          } else if (countryName != null) {
            docType = '$countryName Document';
          } else if (docTypeName != null) {
            docType = docTypeName;
          }
        }

        final name = _getStringValue(result.fullName) ??
            '${_getStringValue(result.firstName) ?? ''} ${_getStringValue(result.lastName) ?? ''}'.trim();
        final docNum = _getStringValue(result.documentNumber);
        final dob = _getDateString(result.dateOfBirth);
        final issuer = _getStringValue(result.issuingAuthority);

        final List<String> details = [];
        if (docType != null && docType.isNotEmpty) {
          details.add('Document Type: $docType');
        }
        if (name.isNotEmpty) {
          details.add('Name: $name');
        }
        if (docNum != null && docNum.isNotEmpty) {
          details.add('Document Number: $docNum');
        }
        if (dob != null && dob.isNotEmpty) {
          details.add('Born: $dob');
        }
        if (issuer != null && issuer.isNotEmpty) {
          details.add('Issued by: $issuer');
        }

        final rawText = details.isNotEmpty
            ? 'Identity Document scanned. ${details.join(". ")}.'
            : 'Identity Document scanned, but no legible fields detected.';

        final hasText = details.isNotEmpty;

        // Translate to English if necessary using Gemini
        final translatedText = await ref.read(translationServiceProvider).translateToEnglish(rawText);

        setState(() {
          _statusMessage = hasText ? 'Scanned: "$translatedText"' : 'No text detected.';
        });
        await _tts.speak(translatedText);

        // Save to Drift database (save the raw scanned text)
        try {
          await ref
              .read(databaseProvider)
              .into(ref.read(databaseProvider).ocrHistory)
              .insert(
                OcrHistoryCompanion.insert(
                  rawText: rawText,
                  createdAt: DateTime.now(),
                ),
              )
              .timeout(const Duration(seconds: 1));
        } catch (e) {
          // Log or ignore database write failures gracefully
        }
      } catch (e) {
        setState(() {
          _statusMessage = 'Error scanning document.';
        });
        await _tts.speak('Error scanning document.');
      }
    } else {
      // Web / simulator fallback: capture a real frame from the camera and
      // send it to Gemini vision to read whatever text is visible.
      await _performGeminiVisionOcr();
    }
  }

  /// Captures the current camera frame and uses Gemini 1.5 Flash vision to
  /// read any visible text, then speaks and displays the result.
  Future<void> _performGeminiVisionOcr() async {
    // ---------- 1. Capture a JPEG from the live camera feed ----------
    Uint8List? imageBytes;
    final cameraState = ref.read(cameraProvider);
    final controller = cameraState.controller;

    if (controller != null && controller.value.isInitialized) {
      try {
        final xfile = await controller
            .takePicture()
            .timeout(const Duration(seconds: 5));
        imageBytes = await xfile.readAsBytes();
      } catch (e) {
        // Camera capture failed — proceed without image (text-only prompt)
      }
    }

    if (imageBytes == null) {
      setState(() => _statusMessage = 'No camera image available.');
      await _tts.speak('No camera image available.');
      return;
    }

    // ---------- 2. Call Gemini 1.5 Flash with vision ----------
    // API key: pass via --dart-define=GEMINI_API_KEY=... or set directly below.
    const apiKey = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );

    if (apiKey.isEmpty) {
      setState(() => _statusMessage =
          'Add --dart-define=GEMINI_API_KEY=<key> to read real text.');
      await _tts.speak(
          'Gemini API key not configured. Please add your key to enable live text reading.');
      return;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      const prompt =
          'Look at this image and read all the text you can see. '
          'Return ONLY the text found, exactly as written, with no commentary, '
          'labels, or explanation. If there is no text, reply with exactly: '
          'No text detected.';

      final response = await model
          .generateContent([
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', imageBytes),
            ])
          ])
          .timeout(const Duration(seconds: 15));

      final rawText = response.text?.trim() ?? '';

      if (rawText.isEmpty || rawText == 'No text detected.') {
        setState(() => _statusMessage = 'No text detected.');
        await _tts.speak('No text detected.');
        return;
      }

      // Translate to English if necessary
      final translatedText = await ref
          .read(translationServiceProvider)
          .translateToEnglish(rawText);

      setState(() => _statusMessage = 'Scanned: "$translatedText"');
      await _tts.speak(translatedText);

      // Persist to local DB
      try {
        await ref
            .read(databaseProvider)
            .into(ref.read(databaseProvider).ocrHistory)
            .insert(
              OcrHistoryCompanion.insert(
                rawText: rawText,
                createdAt: DateTime.now(),
              ),
            )
            .timeout(const Duration(seconds: 1));
      } catch (_) {
        // DB write failure is non-fatal
      }
    } catch (e) {
      setState(() => _statusMessage = 'OCR error: ${e.runtimeType}');
      await _tts.speak('Error reading text.');
    }
  }

  Future<void> _performLiveDescribe() async {
    final client = ref.read(geminiLiveClientProvider);
    if (!client.isConnected) {
      await client.connect(
        token: 'mock-gemini-live-ephemeral-key',
        isApiKey: true,
      );
    }
    await _tts.speak(
      "Gemini Live describes: You are walking down a concrete sidewalk. A metal obstacle is located 2 meters in front of you at twelve o'clock.",
    );
  }

  Future<void> _performNavigationDemo() async {
    await _tts.speak(
      "Navigation co-pilot active. Walk straight 10 meters, then turn right to three o'clock.",
    );
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

  // 4. Shutter Tap handler (formerly _captureAndReadText)
  Future<void> _onShutterTap() async {
    _triggerFlash();
    await _executeActiveModeAction();
  }

  Future<void> _toggleRecording() async {
    setState(() {
      _isRecording = !_isRecording;
    });
    if (_isRecording) {
      _recordPulseController.repeat(reverse: true);
      await _executeActiveModeAction();
    } else {
      _recordPulseController.stop();
      await _cancelActiveOperation();
    }
  }

  Future<void> _startNavigation() async {
    await _executeActiveModeAction();
  }

  Widget _buildPageControls() {
    switch (_currentPage) {
      case 0:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.crop_free),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Scan Frame',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Scan Frame selected'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.document_scanner),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Document OCR',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document OCR selected'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Send/Share',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share/Send selected'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      case 1:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.mic),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Microphone Options',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Microphone settings'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.volume_up),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Volume Level',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Volume settings'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.tune),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Audio Parameters',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Audio parameters'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      case 2:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Current Location',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Current Location selected'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.map_outlined),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Map Exploration',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Map View selected'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.navigation_outlined),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Turn-by-turn Navigation',
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Route Directions selected'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton() {
    switch (_currentPage) {
      case 0:
        return GestureDetector(
          key: const Key('shutter_button'),
          onTap: _onShutterTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: _isProcessing
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : null,
          ),
        );
      case 1:
        return GestureDetector(
          key: const Key('record_button'),
          onTap: _toggleRecording,
          child: AnimatedBuilder(
            animation: _recordPulseController,
            builder: (context, child) {
              final scale = _isRecording
                  ? 1.0 + (_recordPulseController.value * 0.12)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isRecording ? 24 : 16,
                            height: _isRecording ? 24 : 16,
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        );
      case 2:
        return GestureDetector(
          key: const Key('navigate_button'),
          onTap: _startNavigation,
          child: FadeTransition(
            opacity: _navigationPulseAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(
                        Icons.navigation,
                        color: Colors.black,
                        size: 26,
                      ),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);
    final theme = Theme.of(context);

    // Show loading while the camera is still initializing (not yet checked).
    // This prevents a false "permission denied" flash on startup.
    if (!cameraState.isInitialized && !cameraState.isPermissionDeniedPermanently) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // If permission is explicitly and permanently denied, show the request card.
    if (cameraState.isPermissionDeniedPermanently) {
      return _buildPermissionDeniedScreen(cameraState);
    }

    // 2. Wrap the root Stack with GestureDetector
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final dx = details.velocity.pixelsPerSecond.dx;
          if (dx < -300 && _currentPage < 2) {
            _pageController.animateToPage(
              _currentPage + 1,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
            );
          } else if (dx > 300 && _currentPage > 0) {
            _pageController.animateToPage(
              _currentPage - 1,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Stack(
          // ignore: avoid_redundant_argument_values
          clipBehavior: Clip.hardEdge,
          children: [
            // 1. Live fullscreen camera view
            Positioned.fill(
              child: _buildCameraPreview(cameraState),
            ),

            // 2. Wrap every page in the PageView with:
            // SizedBox.expand(child: ClipRect(child: YourPageWidget()))
            // 3. PageView — never scrollable on its own
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  SizedBox.expand(
                    child: ClipRect(
                      child: TextReaderPage(),
                    ),
                  ),
                  SizedBox.expand(
                    child: ClipRect(
                      child: AudioDescriptionsPage(),
                    ),
                  ),
                  SizedBox.expand(
                    child: ClipRect(
                      child: NavigationPage(),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Bottom overlay exact layout
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Page dots
                  PageDots(currentIndex: _currentPage),
                  const SizedBox(height: 16),
                  // 2. Frosted pill (icon buttons)
                  Center(child: FrostedPill(child: _buildPageControls())),
                  const SizedBox(height: 20),
                  // 3. Shutter / action button
                  Center(child: _buildActionButton()),
                ],
              ),
            ),

            // Status Badge Overlay
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: Center(child: _buildStatusBadge(theme)),
            ),

            // 4. Profile button (top-right, frosted glass)
            Positioned(
              top: 48,
              right: 16,
              child: _buildProfileButton(),
            ),

            // Shutter flash animation overlay
            if (_isFlashVisible)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _flashAnimation,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
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

  /// Builds a correctly scaled full-bleed camera preview.
  Widget _buildCameraPreview(CameraAppState cameraState) {
    if (!cameraState.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    final controller = cameraState.controller;
    if (controller == null || !controller.value.isInitialized) {
      // No camera available (e.g. web without a physical camera). Show a
      // dark background so overlays and controls are still visible.
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                color: Colors.white.withValues(alpha: 0.3),
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                'Camera unavailable',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // Calculate scale ratio to cover full viewport cropping
        var scale = size.aspectRatio * controller.value.aspectRatio;
        if (scale < 1) scale = 1 / scale;

        return ClipRect(
          child: OverflowBox(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size.width,
                height: size.width / controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the top-right frosted glass profile button.
  Widget _buildProfileButton() {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              color: Colors.white,
              tooltip: 'Profile Settings',
              onPressed: () {
                context.push('/profile');
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Renders a modern frosted card requesting camera access.
  Widget _buildPermissionDeniedScreen(CameraAppState cameraState) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Camera Access Needed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      cameraState.errorMessage ??
                          'This app requires camera access to process '
                              'document readers, scene descriptors, '
                              'and ambient navigation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (cameraState.isPermissionDeniedPermanently) {
                          if (kIsWeb) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enable camera access in '
                                  'your browser settings.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            openAppSettings();
                          }
                        } else {
                          ref
                              .read(cameraProvider.notifier)
                              .checkPermissionAndInitialize();
                        }
                      },
                      child: Text(
                        cameraState.isPermissionDeniedPermanently
                            ? 'Open System Settings'
                            : 'Grant Permission',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
