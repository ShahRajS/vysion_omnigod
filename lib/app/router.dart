import 'package:go_router/go_router.dart';
import 'package:vysion_omnigod/features/auth/ui/auth_page.dart';
import 'package:vysion_omnigod/features/capture/ui/capture_page.dart';
import 'package:vysion_omnigod/features/onboarding/ui/onboarding_page.dart';
import 'package:vysion_omnigod/features/profile/ui/profile_page.dart';
import 'package:vysion_omnigod/features/settings/ui/settings_page.dart';
import 'package:vysion_omnigod/pages/navigation_page.dart';

/// The global routing provider configuration for Vysion app.
final router = GoRouter(
  initialLocation: '/navigate', // TODO: restore to '/onboarding'
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const CapturePage(),
    ),
    GoRoute(
      path: '/navigate',
      builder: (context, state) => const NavigationPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);
