// FILE: lib/pages/text_reader_page.dart
import 'package:flutter/material.dart';
import 'package:vysion_omnigod/widgets/frosted_chip.dart';

/// Overlay layout for [Page 0] - Text Reader.
/// Displays top-left status chip.
class TextReaderPage extends StatelessWidget {
  const TextReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      // ignore: avoid_redundant_argument_values
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: 56,
          left: 16,
          child: FrostedChip(label: 'Text Reader'),
        ),
      ],
    );
  }
}
