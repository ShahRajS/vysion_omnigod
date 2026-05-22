import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vysion_omnigod/home_screen.dart';

/*
================================================================================
PLATFORM SETUP INSTRUCTIONS:

1. ANDROID:
   Add these camera and audio permissions inside the `<manifest>` root tag of 
   your `android/app/src/main/AndroidManifest.xml`:
   
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   ```

2. iOS:
   Add these keys inside the `<dict>` tag of your `ios/Runner/Info.plist`:
   
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app requires access to the camera to read text...</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app requires access to the microphone...</string>
   ```
================================================================================
*/

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

  runApp(
    const ProviderScope(
      child: VisualAccessibilityAssistantApp(),
    ),
  );
}

/// The root application widget.
class VisualAccessibilityAssistantApp extends StatelessWidget {
  const VisualAccessibilityAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visual Accessibility Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Colors.black,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
