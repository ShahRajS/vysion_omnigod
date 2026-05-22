import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:vysion_omnigod/core/accessibility/haptics.dart';

/// Accessibility-first Onboarding Flow for Vysion.
class OnboardingPage extends StatefulWidget {
  /// Creates the onboarding page.
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTtsAndWelcome();
  }

  Future<void> _initTtsAndWelcome() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _speakWelcome();
  }

  Future<void> _speakWelcome() async {
    await _tts.speak(
      'Welcome to Vysion. We are setting up your personal navigation co-pilot. '
      'To interact, swipe left or right to change modes, and tap anywhere to select. '
      'Please tap the grant permissions button in the middle of the screen to begin.',
    );
  }

  Future<void> _requestPermissions() async {
    await AccessibleHaptics.playModeSwitch();
    await _tts.stop();

    // Geolocator location request
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Camera and audio permissions will be requested implicitly when capture launches,
    // but we explain them clearly here.
    if (mounted) {
      await _tts.speak('Permissions configured. Redirecting to login.');
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vysion Onboarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Replay welcome speech',
            onPressed: () {
              AccessibleHaptics.playModeSwitch();
              _speakWelcome();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Semantics(
                label: 'Vysion App Logo',
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.colorScheme.secondary, width: 4,),
                    ),
                    child: Icon(
                      Icons.remove_red_eye_outlined,
                      size: 72,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Vysion',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your real-time audio-visual walking companion.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                enabled: true,
                excludeSemantics: true,
                label:
                    'Grant Permissions Button. Double tap to grant location access.',
                onTap: _requestPermissions,
                child: SizedBox(
                  height: 80, // Large tap target for accessibility
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _requestPermissions,
                    child: const Text(
                      'GRANT ACCESS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
