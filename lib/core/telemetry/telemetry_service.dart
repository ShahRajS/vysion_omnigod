import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Telemetry levels.
enum TelemetrySeverity {
  /// Information logs.
  info,

  /// Warning logs.
  warning,

  /// Critical error logs.
  error,
}

/// Service to handle application instrumentation, crash logging, and metrics.
class TelemetryService {
  /// Track a user interface event.
  void trackEvent(String eventName, {Map<String, dynamic>? parameters}) {
    developer.log(
      'Telemetry Event: $eventName${parameters != null ? ' - Params: $parameters' : ''}',
      name: 'VysionTelemetry',
    );
    // In production, log via Firebase Analytics or similar
  }

  /// Track a critical error or exception.
  void logException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? context,
  }) {
    developer.log(
      'Telemetry Exception in: $context',
      name: 'VysionTelemetry',
      error: exception,
      stackTrace: stackTrace,
    );
    // In production, upload to Firebase Crashlytics:
    // FirebaseCrashlytics.instance.recordError(exception, stackTrace, reason: context);
  }

  /// Log general system messages.
  void logMessage(
    String message, {
    TelemetrySeverity severity = TelemetrySeverity.info,
  }) {
    developer.log(
      '[$severity] $message',
      name: 'VysionTelemetry',
    );
  }
}

/// Provider for the TelemetryService.
final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService();
});
