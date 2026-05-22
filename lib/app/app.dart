import 'package:flutter/material.dart';
import 'package:vysion_omnigod/app/router.dart';
import 'package:vysion_omnigod/app/theme.dart';
import 'package:vysion_omnigod/l10n/app_localizations.dart';

/// The root application widget.
class VysionApp extends StatelessWidget {
  /// Creates the root application widget.
  const VysionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vysion',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
