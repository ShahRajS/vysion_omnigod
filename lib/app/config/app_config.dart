import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration configuration variables for the Vysion app.
class AppConfig {
  /// Creates the app config from the environmental definitions.
  const AppConfig({
    required this.geminiApiHost,
    required this.mapsApiKeyAndroid,
    required this.mapsApiKeyIos,
    required this.backendBaseUrl,
  });

  /// Reads from the command-line environment (--dart-define) at compile time.
  factory AppConfig.fromEnvironment() {
    const geminiApiHost = String.fromEnvironment('GEMINI_API_HOST');
    const mapsApiKeyAndroid = String.fromEnvironment('MAPS_API_KEY_ANDROID');
    const mapsApiKeyIos = String.fromEnvironment('MAPS_API_KEY_IOS');
    const backendBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');

    if (geminiApiHost.isEmpty ||
        mapsApiKeyAndroid.isEmpty ||
        mapsApiKeyIos.isEmpty ||
        backendBaseUrl.isEmpty) {
      throw StateError(
        'Missing required compile-time variables. Verify --dart-define parameters:\n'
        '- GEMINI_API_HOST\n'
        '- MAPS_API_KEY_ANDROID\n'
        '- MAPS_API_KEY_IOS\n'
        '- BACKEND_BASE_URL',
      );
    }

    return const AppConfig(
      geminiApiHost: geminiApiHost,
      mapsApiKeyAndroid: mapsApiKeyAndroid,
      mapsApiKeyIos: mapsApiKeyIos,
      backendBaseUrl: backendBaseUrl,
    );
  }

  /// Ephemeral host URL for Gemini Live WebSocket connection.
  final String geminiApiHost;

  /// Google Maps SDK Key for Android.
  final String mapsApiKeyAndroid;

  /// Google Maps SDK Key for iOS.
  final String mapsApiKeyIos;

  /// Base orchestration server URL.
  final String backendBaseUrl;
}

/// Provider for the compile-time app configuration.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
