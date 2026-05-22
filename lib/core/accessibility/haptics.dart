import 'package:flutter/services.dart';

/// The accessible haptic feedback engine for Vysion.
class AccessibleHaptics {
  /// Play vibration feedback confirming a mode switch selection.
  static Future<void> playModeSwitch() async {
    await HapticFeedback.selectionClick();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.selectionClick();
  }

  /// Trigger immediate haptic warning when a hazard is identified.
  static Future<void> playHazardWarning() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }

  /// Play haptic sequence confirming arrival at the user's destination.
  static Future<void> playDestinationReached() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
  }

  /// Play haptic sequence indicating an error or cancellation.
  static Future<void> playErrorOrCancel() async {
    await HapticFeedback.vibrate();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.vibrate();
  }
}
