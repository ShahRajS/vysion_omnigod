import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vysion_omnigod/core/accessibility/haptics.dart';
import 'package:vysion_omnigod/features/auth/controllers/auth_controller.dart';

/// Screen exhibiting current logged-in user profile, account settings, and logout triggers.
class ProfilePage extends ConsumerWidget {
  /// Creates the profile page.
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    // Listen for sign-out and redirect to onboarding/auth
    ref.listen<AuthState>(authControllerProvider, (previous, current) {
      if (current.user == null) {
        context.go('/onboarding');
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Your Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Semantics(
                  label: 'User profile avatar icon',
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        theme.colorScheme.secondary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoRow(
                theme: theme,
                label: 'Account Status',
                value: user != null
                    ? (user.isAnonymous ? 'Guest Account' : 'Verified Email')
                    : 'Not Authenticated',
              ),
              const Divider(color: Colors.white24, height: 32),
              _buildInfoRow(
                theme: theme,
                label: 'Unique User ID',
                value: user?.uid ?? 'Unknown ID',
              ),
              const Divider(color: Colors.white24, height: 32),
              if (user != null && !user.isAnonymous) ...[
                _buildInfoRow(
                  theme: theme,
                  label: 'Registered Email',
                  value: user.email ?? 'No email',
                ),
                const Divider(color: Colors.white24, height: 32),
              ],
              const Spacer(),
              Semantics(
                button: true,
                label: 'Sign out. Double tap to terminate session and log out.',
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await AccessibleHaptics.playErrorOrCancel();
                      await ref.read(authControllerProvider.notifier).signOut();
                    },
                    child: const Text(
                      'SIGN OUT / LOG OUT',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
