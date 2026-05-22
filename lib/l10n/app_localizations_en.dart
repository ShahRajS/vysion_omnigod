// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vysion';

  @override
  String get readMode => 'Read';

  @override
  String get describeMode => 'Describe';

  @override
  String get navigateMode => 'Navigate';

  @override
  String get welcomeMessage =>
      'Welcome to Vysion, your accessibility co-pilot.';

  @override
  String get onboardingInstruction =>
      'Swipe left or right to switch modes. Tap to action. Swipe down to cancel speech.';

  @override
  String get startJourney => 'Get Started';

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required to analyze the environment.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required for navigation guidance.';

  @override
  String get microphonePermissionRequired =>
      'Microphone permission is required to talk to the co-pilot.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get settings => 'Settings';

  @override
  String get speechRate => 'Speech Rate';

  @override
  String get hapticIntensity => 'Haptic Feedback Intensity';

  @override
  String get destinationPlaceholder => 'Where to?';

  @override
  String get hazardWarning => 'Alert: Hazard detected in front of you!';

  @override
  String get arrived => 'You have arrived at your destination.';

  @override
  String get ocrReadingError =>
      'Unable to read text from sign. Please try again.';

  @override
  String get navigationCancelled => 'Navigation cancelled.';
}
