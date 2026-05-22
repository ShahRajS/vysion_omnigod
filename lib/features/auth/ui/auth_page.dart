import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vysion_omnigod/core/accessibility/haptics.dart';
import 'package:vysion_omnigod/features/auth/controllers/auth_controller.dart';

/// Screen managing authentication with options for email login and guest entry.
class AuthPage extends ConsumerStatefulWidget {
  /// Creates the auth page.
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEmailSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _handleAnonymousSignIn() {
    ref.read(authControllerProvider.notifier).signInAnonymously();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Automatically route to capture dashboard if logged in
    ref.listen<AuthState>(authControllerProvider, (previous, current) {
      if (current.user != null) {
        AccessibleHaptics.playDestinationReached();
        context.go('/');
      }
      if (current.errorMessage != null &&
          current.errorMessage != previous?.errorMessage) {
        AccessibleHaptics.playErrorOrCancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text(current.errorMessage!),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Access Vysion'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Sign In',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your saved preferences and search history.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 32),
                Semantics(
                  label: 'Email Input field',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty || !val.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  label: 'Password Input field',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                if (authState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Semantics(
                    button: true,
                    label: 'Double tap to sign in with your email account.',
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _handleEmailSignIn,
                        child: const Text(
                          'SIGN IN',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16,),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label:
                        'Skip authentication. Double tap to explore as a guest.',
                    child: SizedBox(
                      height: 60,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.secondary),
                          foregroundColor: theme.colorScheme.secondary,
                        ),
                        onPressed: _handleAnonymousSignIn,
                        child: const Text(
                          'USE ANONYMOUSLY',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16,),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
