import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vysion_omnigod/app/config/app_config.dart';
import 'package:vysion_omnigod/camera_provider.dart';
import 'package:vysion_omnigod/core/ai/translation_service.dart';
import 'package:vysion_omnigod/core/storage/database.dart';
import 'package:vysion_omnigod/features/settings/controllers/settings_controller.dart';
import 'package:vysion_omnigod/home_screen.dart';

class FakeCameraNotifier extends CameraNotifier {
  FakeCameraNotifier() {
    state = CameraAppState(
      cameras: const [],
      isInitialized: false,
      isPermissionGranted: true,
      isPermissionDeniedPermanently: false,
    );
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> checkPermissionAndInitialize() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_tts');
  final List<String> spokenText = [];

  setUp(() {
    spokenText.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'speak') {
        spokenText.add(methodCall.arguments as String);
        return 1;
      }
      if (methodCall.method == 'stop') {
        return 1;
      }
      if (methodCall.method == 'setSpeechRate') {
        return 1;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('HomeScreen loads successfully and triggers OCR simulation',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraProvider.overrideWith((ref) => FakeCameraNotifier()),
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          translationServiceProvider.overrideWithValue(FakeTranslationService()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Wait for camera initialization (which falls back gracefully in tests)
    await tester.pump(const Duration(seconds: 2));

    // Verify initial layout elements for Text Reader (Page 0) are displayed
    expect(find.byType(CircularProgressIndicator), findsOneWidget); // Viewfinder loading fallback
    expect(find.text('Text Reader'), findsOneWidget); // Positioned FrostedChip
    expect(find.byKey(const Key('shutter_button')), findsOneWidget); // Test key shutter button

    // Reset spoken logs for action testing
    spokenText.clear();

    // Trigger action (tap the shutter button to execute READ mode action)
    final shutterFinder = find.byKey(const Key('shutter_button'));
    expect(shutterFinder, findsOneWidget);
    await tester.tap(shutterFinder, warnIfMissed: true);
    await tester.pump(const Duration(milliseconds: 500));

    // The shutter triggers _executeActiveModeAction, which calls _tts.speak('Processing input.')
    expect(spokenText, contains('Processing input.'));

    // Wait for the translation service and DB write to finish
    await tester.pump(const Duration(seconds: 2));

    // The fallback simulation on non-web/test platforms for _performOcr yields:
    // "Identity Document scanned. Document Type: USA DRIVER LICENSE. Name: JOHN DOE. Document Number: D1234567. Born: 1990-12-14."
    // Let's verify that the OCR scanned result was spoken and stored.
    expect(
      spokenText.any((text) => text.contains('Identity Document scanned')),
      isTrue,
    );

    // Check if the history was written to the Drift database
    final history = await db.select(db.ocrHistory).get();
    expect(history.length, 1);
    expect(history.first.rawText, contains('Identity Document scanned'));

    await db.close();
  });
}

class FakeTranslationService implements TranslationService {
  @override
  AppConfig get config => throw UnimplementedError();

  @override
  Ref get ref => throw UnimplementedError();

  @override
  Future<String> translateToEnglish(String text) async {
    return text;
  }
}
