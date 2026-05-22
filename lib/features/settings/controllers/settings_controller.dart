import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State representation of the user settings.
class SettingsState {
  /// Creates settings state.
  const SettingsState({
    required this.speechRate,
    required this.hapticIntensity,
    required this.avoidObstacles,
  });

  /// Speech rate multiplier for TTS (e.g. 0.5 to 1.5).
  final double speechRate;

  /// Haptic intensity multiplier.
  final double hapticIntensity;

  /// Whether routing should actively avoid stairs and visual obstacles.
  final bool avoidObstacles;

  /// Creates a copy of current settings with overrides.
  SettingsState copyWith({
    double? speechRate,
    double? hapticIntensity,
    bool? avoidObstacles,
  }) {
    return SettingsState(
      speechRate: speechRate ?? this.speechRate,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      avoidObstacles: avoidObstacles ?? this.avoidObstacles,
    );
  }
}

/// Notifier to manage loading and updating preferences in SharedPreferences.
class SettingsNotifier extends StateNotifier<SettingsState> {
  /// Instantiates SettingsNotifier.
  SettingsNotifier(this._prefs)
      : super(SettingsState(
          speechRate: _prefs.getDouble(_speechRateKey) ?? 0.5,
          hapticIntensity: _prefs.getDouble(_hapticIntensityKey) ?? 1.0,
          avoidObstacles: _prefs.getBool(_avoidObstaclesKey) ?? false,
        ),);

  final SharedPreferences _prefs;

  static const _speechRateKey = 'settings_speech_rate';
  static const _hapticIntensityKey = 'settings_haptic_intensity';
  static const _avoidObstaclesKey = 'settings_avoid_obstacles';

  /// Updates TTS speech rate.
  Future<void> setSpeechRate(double val) async {
    await _prefs.setDouble(_speechRateKey, val);
    state = state.copyWith(speechRate: val);
  }

  /// Updates haptic feedback scaling intensity.
  Future<void> setHapticIntensity(double val) async {
    await _prefs.setDouble(_hapticIntensityKey, val);
    state = state.copyWith(hapticIntensity: val);
  }

  /// Updates avoid obstacles walking routing preference.
  Future<void> setAvoidObstacles({required bool val}) async {
    await _prefs.setBool(_avoidObstaclesKey, val);
    state = state.copyWith(avoidObstacles: val);
  }
}

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Riverpod provider for SettingsState.
final settingsControllerProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
