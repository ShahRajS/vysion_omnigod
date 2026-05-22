// FILE: lib/home_screen.dart
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:vysion_omnigod/camera_provider.dart';
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
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flashController.dispose();
    _recordPulseController.dispose();
    _navigationPulseController.dispose();
    super.dispose();
  }

  void _triggerFlash() {
    setState(() {
      _isFlashVisible = true;
    });
    _flashController.forward(from: 0);
  }

  // 4. Shutter Tap handler (formerly _captureAndReadText)
  void _onShutterTap() {
    _triggerFlash();
    debugPrint('TEXT READER: capture triggered');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading text...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _recordPulseController.repeat(reverse: true);
        _describeScene();
      } else {
        _recordPulseController.stop();
      }
    });
  }

  void _describeScene() {
    debugPrint('AUDIO DESC: scene description triggered');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Describing scene...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startNavigation() {
    debugPrint('NAV: navigation triggered');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting navigation...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
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
          onTap: _onShutterTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      case 1:
        return GestureDetector(
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
                    child: AnimatedContainer(
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
              child: const Center(
                child: Icon(
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

    // If permission is denied, overlay the centered dark card immediately
    if (!cameraState.isPermissionGranted) {
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
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
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
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile settings triggered'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
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
