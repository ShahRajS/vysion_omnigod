// FILE: lib/camera_provider.dart
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// State representation for the camera module.
class CameraAppState {
  CameraAppState({
    required this.cameras,
    required this.isInitialized,
    required this.isPermissionGranted,
    required this.isPermissionDeniedPermanently,
    this.controller,
    this.errorMessage,
  });

  final List<CameraDescription> cameras;
  final CameraController? controller;
  final bool isInitialized;
  final bool isPermissionGranted;
  final bool isPermissionDeniedPermanently;
  final String? errorMessage;

  CameraAppState copyWith({
    List<CameraDescription>? cameras,
    CameraController? controller,
    bool? isInitialized,
    bool? isPermissionGranted,
    bool? isPermissionDeniedPermanently,
    String? errorMessage,
  }) {
    return CameraAppState(
      cameras: cameras ?? this.cameras,
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isPermissionDeniedPermanently:
          isPermissionDeniedPermanently ?? this.isPermissionDeniedPermanently,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// A state notifier managing camera permissions and the controller lifecycle.
class CameraNotifier extends StateNotifier<CameraAppState> {
  CameraNotifier()
      : super(
          CameraAppState(
            cameras: const [],
            isInitialized: false,
            isPermissionGranted: false,
            isPermissionDeniedPermanently: false,
          ),
        ); // Constructor is synchronous and safe

  /// Explicit initialization method called from the UI lifecycle.
  Future<void> init() async {
    await checkPermissionAndInitialize();
  }

  /// Request camera permission safely (web-friendly).
  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Permission check failed: $e — proceeding without it');
      return true;
    }
  }

  /// Request microphone permission safely (web-friendly).
  @visibleForTesting
  // ignore: unused_element
  Future<bool> requestMicPermission() async {
    if (kIsWeb) return true;

    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Mic permission check failed: $e');
      return true;
    }
  }

  /// Checks for permissions and attempts to initialize the camera controller.
  Future<void> checkPermissionAndInitialize() async {
    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        state = CameraAppState(
          cameras: const [],
          isInitialized: false,
          isPermissionGranted: false,
          isPermissionDeniedPermanently: true,
          errorMessage: 'Camera permission permanently denied. '
              'Please open settings to enable camera access.',
        );
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = CameraAppState(
          cameras: const [],
          isInitialized: false,
          isPermissionGranted: true,
          isPermissionDeniedPermanently: false,
          errorMessage: 'No available cameras found on this device.',
        );
        return;
      }

      // Dispose existing controller if any
      if (state.controller != null) {
        await state.controller!.dispose();
      }

      // Use the first (primary back) camera
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      state = CameraAppState(
        cameras: cameras,
        controller: controller,
        isInitialized: false,
        isPermissionGranted: true,
        isPermissionDeniedPermanently: false,
        errorMessage: 'Starting camera...',
      );

      await controller.initialize();

      state = CameraAppState(
        cameras: state.cameras,
        controller: state.controller,
        isInitialized: true,
        isPermissionGranted: true,
        isPermissionDeniedPermanently: false,
      );
    } catch (e) {
      debugPrint('Camera init error: $e');
      state = CameraAppState(
        cameras: state.cameras,
        controller: state.controller,
        isInitialized: false,
        isPermissionGranted: true,
        isPermissionDeniedPermanently: false,
        errorMessage: 'Failed to start camera. Error: $e',
      );
    }
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}

/// Provider to access and control the camera state throughout the app.
final cameraProvider =
    StateNotifierProvider<CameraNotifier, CameraAppState>((ref) {
  // Notifier is returned cleanly without triggering async operations here.
  return CameraNotifier();
});
