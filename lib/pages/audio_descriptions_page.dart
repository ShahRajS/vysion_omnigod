// FILE: lib/pages/audio_descriptions_page.dart
import 'package:flutter/material.dart';
import 'package:vysion_omnigod/widgets/frosted_chip.dart';

/// Overlay layout for [Page 1] - Audio Descriptions.
/// Displays top-left status chip.
class AudioDescriptionsPage extends StatelessWidget {
  const AudioDescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      // ignore: avoid_redundant_argument_values
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: 56,
          left: 16,
          child: FrostedChip(label: 'Audio Descriptions'),
        ),
      ],
    );
  }
}
