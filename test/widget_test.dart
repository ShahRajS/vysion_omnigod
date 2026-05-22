import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vysion_omnigod/features/onboarding/ui/onboarding_page.dart';

void main() {
  testWidgets('Onboarding page accessibility semantics test',
      (WidgetTester tester) async {
    // Build OnboardingPage within ProviderScope and MaterialApp
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingPage(),
        ),
      ),
    );

    // Verify Title and primary elements exist
    expect(find.text('Vysion'), findsOneWidget);
    expect(find.text('Your real-time audio-visual walking companion.'),
        findsOneWidget,);
    expect(find.text('GRANT ACCESS'), findsOneWidget);

    // Verify presence of accessible button semantic properties
    final buttonFinder = find.byType(ElevatedButton);
    expect(buttonFinder, findsOneWidget);

    // Verify semantics match using standard matchesSemantics matcher
    expect(
      tester.getSemantics(buttonFinder),
      matchesSemantics(
        label: 'Grant Permissions Button. Double tap to grant location access.',
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
  });
}
