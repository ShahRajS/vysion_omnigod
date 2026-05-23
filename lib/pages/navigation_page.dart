import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vysion_omnigod/services/gemini_live_service.dart';
import 'package:vysion_omnigod/services/maps_navigation_service.dart';
import 'package:vysion_omnigod/widgets/gemini_orb.dart';
import 'package:vysion_omnigod/widgets/map_pip.dart';
import 'package:vysion_omnigod/widgets/turn_banner.dart';

class NavigationPage extends ConsumerStatefulWidget {
  const NavigationPage({super.key});

  @override
  ConsumerState<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends ConsumerState<NavigationPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  late MapsNavigationService _mapsService;
  late GeminiLiveService _geminiService;

  final _destinationController = TextEditingController();
  final _destinationFocus = FocusNode();
  final _tts = FlutterTts();
  StreamSubscription<dynamic>? _positionSub;

  GeminiLiveState _geminiState = GeminiLiveState.disconnected;
  bool _isNavigating = false;
  bool _mapVisible = true;
  TurnStep? _currentStep;
  List<LatLng> _polyline = [];
  LatLng? _destination;
  LatLng? _currentPosition;
  bool _isLoading = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mapsService = ref.read(mapsNavigationServiceProvider);
    _geminiService = ref.read(geminiLiveServiceProvider);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _geminiService.stateNotifier.addListener(_onGeminiStateChanged);
    _mapsService.isNavigatingNotifier.addListener(_onNavStateChanged);
    _mapsService.stepIndexNotifier.addListener(_onStepChanged);
    _mapsService.polylineNotifier.addListener(_onPolylineChanged);
    _mapsService.destinationNotifier.addListener(_onDestinationChanged);

    _initCamera();
    _initLocationStream();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _initLocationStream() {
    _positionSub = _mapsService.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
      }
    });
  }

  void _onGeminiStateChanged() {
    if (!mounted) return;
    final state = _geminiService.state;
    setState(() => _geminiState = state);
    if (state == GeminiLiveState.listening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _onNavStateChanged() {
    if (!mounted) return;
    setState(() => _isNavigating = _mapsService.isNavigating);
  }

  void _onStepChanged() {
    if (!mounted) return;
    setState(() => _currentStep = _mapsService.currentStep);
  }

  void _onPolylineChanged() {
    if (!mounted) return;
    setState(() => _polyline = _mapsService.polylineNotifier.value);
  }

  void _onDestinationChanged() {
    if (!mounted) return;
    setState(() => _destination = _mapsService.destinationNotifier.value);
  }

  Future<void> _startNavigation(String query) async {
    if (query.trim().isEmpty) return;
    _destinationFocus.unfocus();
    setState(() => _isLoading = true);

    final ok = await _mapsService.startNavigation(query);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!ok) {
      await _tts.speak("Couldn't find route. Try again.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't find route — try again")),
        );
      }
      return;
    }

    if (!mounted) return;

    if (_cameraController != null &&
        _cameraController!.value.isInitialized) {
      await _geminiService.connect(_cameraController!);
    }

    if (!mounted) return;
  }

  Future<void> _stopNavigation() async {
    await _geminiService.disconnect();
    await _mapsService.stopNavigation();
  }

  @override
  void dispose() {
    _geminiService.stateNotifier.removeListener(_onGeminiStateChanged);
    _mapsService.isNavigatingNotifier.removeListener(_onNavStateChanged);
    _mapsService.stepIndexNotifier.removeListener(_onStepChanged);
    _mapsService.polylineNotifier.removeListener(_onPolylineChanged);
    _mapsService.destinationNotifier.removeListener(_onDestinationChanged);
    _positionSub?.cancel();
    _geminiService.pauseFrames();
    unawaited(_geminiService.disconnect());
    unawaited(_mapsService.stopNavigation());
    _cameraController?.dispose();
    _destinationController.dispose();
    _destinationFocus.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCamera =
        _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera preview
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

          // 2. Turn banner
          if (_isNavigating && _currentStep != null)
            Positioned(
              top: 56,
              left: 16,
              right: 16,
              child: TurnBanner(step: _currentStep!),
            ),

          // 3. Gemini orb
          if (_geminiState != GeminiLiveState.disconnected)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(child: GeminiOrb(state: _geminiState)),
            ),

          // 4. Page label
          Positioned(
            top: 56,
            left: 16,
            child: _FrostedChip(label: 'Navigation'),
          ),

          // 5. Map PiP
          MapPip(
            polyline: _polyline,
            currentPosition: _currentPosition,
            destination: _destination,
            visible: _mapVisible && _isNavigating,
          ),

          // 6. Bottom controls
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDestinationBar(),
                const SizedBox(height: 16),
                if (_isNavigating) _buildNavControls(),
                if (_isNavigating) const SizedBox(height: 16),
                _buildActionButton(),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: TextField(
              controller: _destinationController,
              focusNode: _destinationFocus,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Where to?',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white54),
              ),
              onSubmitted: _startNavigation,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavControls() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.location_on_outlined,
                    color: Colors.white),
                onPressed: () {},
                tooltip: 'Center on location',
              ),
              IconButton(
                icon: Icon(
                  _mapVisible
                      ? Icons.map_outlined
                      : Icons.map,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _mapVisible = !_mapVisible),
                tooltip: 'Toggle map',
              ),
              IconButton(
                icon: const Icon(Icons.navigation_outlined,
                    color: Colors.white),
                onPressed: () {
                  final q = _destinationController.text;
                  if (q.isNotEmpty) _startNavigation(q);
                },
                tooltip: 'Recalculate route',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _isNavigating ? _stopNavigation : () {
        final q = _destinationController.text;
        if (q.isNotEmpty) _startNavigation(q);
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final opacity = _geminiState == GeminiLiveState.listening
              ? 0.7 + 0.3 * _pulseController.value
              : 1.0;
          return Opacity(opacity: opacity, child: child);
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: _isNavigating
                ? Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  )
                : const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FrostedChip extends StatelessWidget {
  const _FrostedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
