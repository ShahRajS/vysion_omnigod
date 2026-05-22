import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:vysion_omnigod/app/config/app_config.dart';
import 'package:vysion_omnigod/features/auth/controllers/auth_controller.dart';

/// Service that leverages Gemini to detect and translate text to English.
class TranslationService {
  /// Creates the translation service.
  TranslationService({required this.config, required this.ref});

  /// The application configuration.
  final AppConfig config;

  /// The Riverpod reference.
  final Ref ref;

  /// Translates non-English text to English if necessary.
  ///
  /// If the text is already in English or the translation fails/is in development
  /// mock mode, it returns the text appropriately.
  Future<String> translateToEnglish(String text) async {
    if (text.trim().isEmpty) return text;

    try {
      // If backend URL is empty or invalid, skip network call and simulate translation/fallback
      if (config.backendBaseUrl.isEmpty || !config.backendBaseUrl.startsWith('http')) {
        return _simulateTranslation(text);
      }

      final user = ref.read(authControllerProvider).user;
      final idToken = user != null ? await user.getIdToken() : 'mock-token';

      final response = await http.get(
        Uri.parse('${config.backendBaseUrl}/v1/gemini/token'),
        headers: {'Authorization': 'Bearer $idToken'},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch Gemini token from backend: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final apiKey = data['token'] as String?;

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API token returned from backend');
      }

      // If mock token is returned, simulate translation locally
      if (apiKey.startsWith('mock-')) {
        return _simulateTranslation(text);
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final prompt = 'Identify the language of the following text. '
          'If the text is NOT in English, translate it to English. '
          'If it is already in English, return it exactly as it is without any changes. '
          'Do NOT add any notes, headers, explanations, markdown quotes, or introductory text. '
          'Just return the final English text itself:\n\n$text';

      final content = [Content.text(prompt)];
      final responseObj = await model.generateContent(content).timeout(const Duration(seconds: 3));
      final translated = responseObj.text;

      if (translated == null || translated.trim().isEmpty) {
        return text;
      }
      return translated.trim();
    } catch (e) {
      // Fallback to original text on failure
      return text;
    }
  }

  /// Simple local simulation of translation for development/test environments.
  String _simulateTranslation(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('hola')) {
      return 'Hello';
    }
    if (lower.contains('salida')) {
      return 'Exit';
    }
    if (lower.contains('tren')) {
      return 'Train';
    }
    if (lower.contains('plataforma')) {
      return 'Platform';
    }
    if (lower.contains('peligro')) {
      return 'Danger';
    }
    return text;
  }
}

/// Provider for the TranslationService instance.
final translationServiceProvider = Provider<TranslationService>((ref) {
  final config = ref.watch(appConfigProvider);
  return TranslationService(config: config, ref: ref);
});
