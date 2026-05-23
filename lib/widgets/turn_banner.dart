import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vysion_omnigod/services/maps_navigation_service.dart';

const _maneuverIcons = <String, IconData>{
  'turn-left': Icons.turn_left,
  'turn-right': Icons.turn_right,
  'straight': Icons.straight,
  'roundabout-left': Icons.rotate_left,
  'roundabout-right': Icons.rotate_right,
  'uturn-left': Icons.u_turn_left,
  'uturn-right': Icons.u_turn_right,
  'merge': Icons.merge,
  'ramp-left': Icons.turn_slight_left,
  'ramp-right': Icons.turn_slight_right,
};

class TurnBanner extends StatelessWidget {
  const TurnBanner({required this.step, super.key});

  final TurnStep step;

  String get _distanceLabel {
    if (step.distanceMeters >= 1000) {
      return '${(step.distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${step.distanceMeters} m';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(step.instruction),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _maneuverIcons[step.maneuver] ?? Icons.straight,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _distanceLabel,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
