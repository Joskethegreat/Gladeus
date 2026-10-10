import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// White track with an orange thumb. Drag the thumb across to confirm.
/// Releases early spring back; the thumb follows the finger 1:1 while dragging.
class SlideToStop extends StatefulWidget {
  final VoidCallback onComplete;
  final String label;

  const SlideToStop({
    super.key,
    required this.onComplete,
    this.label = 'Swipe to stop',
  });

  @override
  State<SlideToStop> createState() => _SlideToStopState();
}

class _SlideToStopState extends State<SlideToStop>
    with SingleTickerProviderStateMixin {
  static const _trackHeight = 64.0;
  static const _thumbSize = 56.0;
  static const _inset = (_trackHeight - _thumbSize) / 2;
  static const _accent = Color(0xFFF5A623);
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 28,
  );

  late final AnimationController _ctrl = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  double _max = 1;
  bool _done = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    if (_done) return;
    _ctrl.stop(); // grab it mid-flight
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_done) return;
    _ctrl.value = (_ctrl.value + d.delta.dx).clamp(0.0, _max);
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    if (_done) return;
    final v = d.primaryVelocity ?? 0;
    // Decide using where the gesture is heading, not just where it ended.
    final projected = _ctrl.value + v * 0.15;
    final complete = projected > _max * 0.85;

    if (complete) {
      _done = true;
      HapticFeedback.mediumImpact();
      await _ctrl
          .animateWith(SpringSimulation(_spring, _ctrl.value, _max, v))
          .orCancel
          .catchError((_) {});
      if (mounted) widget.onComplete();
    } else {
      _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 0, v));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _max = c.maxWidth - _thumbSize - _inset * 2;
        return Semantics(
          label: widget.label,
          button: true,
          // Always sits over the dark camera feed, so these are fixed light-on-dark values.
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_trackHeight / 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_trackHeight / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: _trackHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x38FFFFFF),
                        Color(0x14FFFFFF),
                      ], // light catching the top
                    ),
                    border: Border.all(
                      color: const Color(0x4DFFFFFF),
                      width: 1,
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      final progress = (_ctrl.value / _max).clamp(0.0, 1.0);
                      return Stack(
                        children: [
                          // Label fades as the thumb passes over it.
                          Center(
                            child: Opacity(
                              opacity: (1 - progress * 2).clamp(0.0, 1.0),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: _thumbSize,
                                ),
                                child: Text(
                                  widget.label,
                                  style: const TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: _inset + _ctrl.value,
                            top: _inset,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart: _onDragStart,
                              onHorizontalDragUpdate: _onDragUpdate,
                              onHorizontalDragEnd: _onDragEnd,
                              child: Container(
                                width: _thumbSize,
                                height: _thumbSize,
                                decoration: const BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 32,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
