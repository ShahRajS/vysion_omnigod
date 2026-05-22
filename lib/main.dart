import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vysion_omnigod/app/app.dart';
import 'package:vysion_omnigod/features/settings/controllers/settings_controller.dart';
import 'package:vysion_omnigod/firebase_options.dart';

void main() async {
  // Ensure framework services are initialized prior to launching screen
  WidgetsFlutterBinding.ensureInitialized();

  // Enable a fully fullscreen immersive sticky UI (hides overlays)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Set the system navigation bars and status bars to transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set up Flutter global error logging instead of printing.
  FlutterError.onError = (details) {
    developer.log(
      'Flutter error caught: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    developer.log(
      'Firebase initialization failed',
      error: e,
      stackTrace: stack,
    );
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const VysionApp(),
    ),
  );
}
