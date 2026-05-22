import 'package:go_router/go_router.dart';
import 'package:vysion_omnigod/features/auth/ui/auth_page.dart';
import 'package:vysion_omnigod/features/onboarding/ui/onboarding_page.dart';
import 'package:vysion_omnigod/features/profile/ui/profile_page.dart';
import 'package:vysion_omnigod/features/settings/ui/settings_page.dart';
import 'package:vysion_omnigod/home_screen.dart';

/// The global routing provider configuration for Vysion app.
final router = GoRouter(
  initialLocation: '/onboarding',
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
      builder: (context, state) => const HomeScreen(),
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
