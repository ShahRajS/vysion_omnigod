import 'package:flutter/material.dart';

/// The gesture actions user can perform in Vysion.
enum GestureAction {
  /// Swiped left.
  swipeLeft,

  /// Swiped right.
  swipeRight,

  /// Swiped down.
  swipeDown,

  /// Tap.
  tap,

  /// Double tap.
  doubleTap,

  /// Long press.
  longPress,
}

/// A widget that decodes screen gestures into [GestureAction] callbacks.
class AccessibilityGestureDecoder extends StatelessWidget {
  /// Creates the gesture decoder.
  const AccessibilityGestureDecoder({
    required this.child,
    required this.onAction,
    super.key,
  });

  /// The child widget.
  final Widget child;

  /// Callback when a gesture action is parsed.
  final ValueChanged<GestureAction> onAction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            onAction(GestureAction.swipeRight);
          } else {
            onAction(GestureAction.swipeLeft);
          }
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          onAction(GestureAction.swipeDown);
        }
      },
      onTap: () => onAction(GestureAction.tap),
      onDoubleTap: () => onAction(GestureAction.doubleTap),
      onLongPress: () => onAction(GestureAction.longPress),
      child: Semantics(
        label:
            'Vysion screen gesture pad. Swipe left or right to change modes, '
            'swipe down to cancel, tap to act, double tap to cancel operations.',
        child: child,
      ),
    );
  }
}
