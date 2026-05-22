// FILE: lib/widgets/frosted_pill.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium frosted-glass styled rounded pill.
/// Used to contain secondary horizontal options on all pages.
class FrostedPill extends StatelessWidget {
  const FrostedPill({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.18),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
