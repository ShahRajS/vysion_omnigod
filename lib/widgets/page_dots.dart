// FILE: lib/widgets/page_dots.dart
import 'package:flutter/material.dart';

/// A custom page indicator with dynamic resizing transition dots.
/// Used to represent which accessibility tool page is active.
class PageDots extends StatelessWidget {
  const PageDots({
    required this.currentIndex,
    this.pageCount = 3,
    super.key,
  });

  final int currentIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
