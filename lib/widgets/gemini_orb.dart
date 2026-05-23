import 'package:flutter/material.dart';
import 'package:vysion_omnigod/services/gemini_live_service.dart';

class GeminiOrb extends StatefulWidget {
  const GeminiOrb({required this.state, super.key});

  final GeminiLiveState state;

  @override
  State<GeminiOrb> createState() => _GeminiOrbState();
}

class _GeminiOrbState extends State<GeminiOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _speakController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _speakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(GeminiOrb old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _syncAnimation();
  }

  void _syncAnimation() {
    switch (widget.state) {
      case GeminiLiveState.connecting:
        _speakController.stop();
        _pulseController.repeat(reverse: true);
      case GeminiLiveState.listening:
        _speakController.stop();
        _pulseController.repeat(reverse: true);
      case GeminiLiveState.speaking:
        _pulseController.stop();
        _speakController.repeat(reverse: true);
      case GeminiLiveState.disconnected:
      case GeminiLiveState.error:
        _pulseController.stop();
        _speakController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speakController.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.state) {
        GeminiLiveState.disconnected => Colors.white.withValues(alpha: 0.3),
        GeminiLiveState.connecting => Colors.amber,
        GeminiLiveState.listening => Colors.green,
        GeminiLiveState.speaking => Colors.blue,
        GeminiLiveState.error => Colors.red,
      };

  String get _label => switch (widget.state) {
        GeminiLiveState.disconnected => 'Disconnected',
        GeminiLiveState.connecting => 'Connecting',
        GeminiLiveState.listening => 'Listening',
        GeminiLiveState.speaking => 'Speaking',
        GeminiLiveState.error => 'Error',
      };

  @override
  Widget build(BuildContext context) {
    if (widget.state == GeminiLiveState.speaking) {
      return Tooltip(
        message: _label,
        child: AnimatedBuilder(
          animation: _speakController,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (i * 0.3 + _speakController.value) % 1.0;
                final height = 4.0 + 8.0 * phase;
                return Container(
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              }),
            );
          },
        ),
      );
    }

    return Tooltip(
      message: _label,
      child: ScaleTransition(
        scale: widget.state == GeminiLiveState.connecting ||
                widget.state == GeminiLiveState.listening
            ? Tween<double>(begin: 0.8, end: 1.2).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: Curves.easeInOut,
                ),
              )
            : const AlwaysStoppedAnimation(1),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
