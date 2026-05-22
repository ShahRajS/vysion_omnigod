import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vysion_omnigod/core/accessibility/haptics.dart';
import 'package:vysion_omnigod/core/storage/database.dart';
import 'package:vysion_omnigod/features/settings/controllers/settings_controller.dart';

/// Settings screen for configuring speech, haptics, and clearing database logs.
class SettingsPage extends ConsumerWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final database = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Voice & Control Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildSectionHeader(theme, 'Speech Options'),
          const SizedBox(height: 8),
          Semantics(
            label:
                'Speech Speed. Current multiplier: ${settings.speechRate.toStringAsFixed(1)}',
            value: '${(settings.speechRate * 100).toInt()}%',
            slider: true,
            child: Row(
              children: [
                const Icon(Icons.speed, color: Colors.white70),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: settings.speechRate,
                    min: 0.3,
                    max: 1.5,
                    divisions: 12,
                    activeColor: theme.colorScheme.secondary,
                    onChanged: (val) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setSpeechRate(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'Haptic Settings'),
          const SizedBox(height: 8),
          Semantics(
            label:
                'Haptic Vibration Strength. Current multiplier: ${settings.hapticIntensity.toStringAsFixed(1)}',
            value: '${(settings.hapticIntensity * 100).toInt()}%',
            slider: true,
            child: Row(
              children: [
                const Icon(Icons.vibration, color: Colors.white70),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: settings.hapticIntensity,
                    max: 2,
                    divisions: 8,
                    activeColor: theme.colorScheme.secondary,
                    onChanged: (val) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setHapticIntensity(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'Routing Preferences'),
          Semantics(
            label:
                'Avoid stairs and obstacle hazards. Currently ${settings.avoidObstacles ? 'enabled' : 'disabled'}',
            value: settings.avoidObstacles ? 'On' : 'Off',
            child: SwitchListTile(
              title: const Text('Avoid Stairs & Hazards'),
              subtitle: const Text(
                  'Route walking directions around construction and escalators',),
              value: settings.avoidObstacles,
              activeThumbColor: theme.colorScheme.secondary,
              onChanged: (val) async {
                await AccessibleHaptics.playModeSwitch();
                await ref
                    .read(settingsControllerProvider.notifier)
                    .setAvoidObstacles(val: val);
              },
            ),
          ),
          const SizedBox(height: 36),
          _buildSectionHeader(theme, 'Data & Persistence'),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label:
                'Double tap to purge local database caches of OCR and descriptions.',
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_sweep),
                label: const Text(
                  'CLEAR LOCAL HISTORY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await AccessibleHaptics.playErrorOrCancel();

                  // Purge database history using generated tables
                  await database.transaction(() async {
                    await database.delete(database.ocrHistory).go();
                    await database.delete(database.descriptionHistory).go();
                    await database.delete(database.destinations).go();
                  });

                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('All offline logs successfully cleared.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.secondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
