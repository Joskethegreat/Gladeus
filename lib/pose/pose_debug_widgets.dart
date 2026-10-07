import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import 'movenet_pose_detector.dart';
import 'rep_counter.dart';

/// Draws the skeleton + keypoints. Coordinates are normalized (0..1) in the
/// image the model saw, so this works over the preview or the model-input
/// thumbnail alike. [mirrorX] flips for a mirrored front-camera preview.
class SkeletonPainter extends CustomPainter {
  final List<Keypoint> keypoints;
  final List<int> tracked;
  final bool mirrorX;
  final bool labels;

  SkeletonPainter(this.keypoints, {this.tracked = const [], this.mirrorX = false, this.labels = false});

  Offset _pos(Keypoint k, Size size) =>
      Offset((mirrorX ? 1 - k.x : k.x) * size.width, k.y * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final bonePaint = Paint()
      ..strokeWidth = 2
      ..color = Colors.white54;
    for (final b in KeypointIndex.bones) {
      final a = keypoints[b[0]];
      final c = keypoints[b[1]];
      if (a.score >= RepCounter.minScore && c.score >= RepCounter.minScore) {
        canvas.drawLine(_pos(a, size), _pos(c, size), bonePaint);
      }
    }
    for (var i = 0; i < keypoints.length; i++) {
      final k = keypoints[i];
      final ok = k.score >= RepCounter.minScore;
      final isTracked = tracked.contains(i);
      final paint = Paint()
        ..color = ok ? (isTracked ? Colors.cyanAccent : Colors.greenAccent) : Colors.redAccent;
      final p = _pos(k, size);
      canvas.drawCircle(p, isTracked ? 6 : 4, paint);
      if (labels) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${KeypointIndex.names[i]} ${k.score.toStringAsFixed(2)}',
            style: TextStyle(color: paint.color, fontSize: 10, backgroundColor: Colors.black45),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p + const Offset(6, -5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter old) => true;
}

class _PanelBox extends StatelessWidget {
  final Widget child;
  const _PanelBox({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );
}

/// Debug mode: what the model sees, detected nodes with scores, and counter state.
class DebugPanel extends StatelessWidget {
  final ui.Image? modelInput;
  final ui.Image? processedFrame;
  final List<Keypoint>? keypoints;
  final RepCounter? counter;
  final String inputType;
  final double fps;
  final double totalMs;
  final double inferMs;

  const DebugPanel({
    super.key,
    required this.modelInput,
    required this.processedFrame,
    required this.keypoints,
    required this.counter,
    required this.inputType,
    required this.fps,
    required this.totalMs,
    required this.inferMs,
  });

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace', height: 1.25);
    final kp = keypoints;
    final detected = kp?.where((k) => k.score >= RepCounter.minScore).length ?? 0;
    return _PanelBox(
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              processedFrame == null
                  ? 'AFTER CONVERT+ROTATE'
                  : 'AFTER CONVERT+ROTATE (${processedFrame!.width}x${processedFrame!.height})',
              style: mono,
            ),
            const SizedBox(height: 4),
            if (processedFrame != null)
              AspectRatio(
                aspectRatio: processedFrame!.width / processedFrame!.height,
                child: RawImage(image: processedFrame, fit: BoxFit.fill),
              )
            else
              const AspectRatio(aspectRatio: 1, child: ColoredBox(color: Colors.black)),
            const SizedBox(height: 8),
            const Text('MODEL INPUT (192x192, squashed)', style: mono),
            const SizedBox(height: 4),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (modelInput != null)
                      RawImage(image: modelInput, fit: BoxFit.fill)
                    else
                      const ColoredBox(color: Colors.black),
                    if (kp != null)
                      CustomPaint(
                        painter: SkeletonPainter(kp, tracked: counter?.trackedJoints ?? const []),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('input: ${inputType.isEmpty ? "?" : inputType}', style: mono),
            Text('fps ${fps.toStringAsFixed(1)}  total ${totalMs.toStringAsFixed(0)}ms', style: mono),
            Text('model ${inferMs.toStringAsFixed(0)}ms', style: mono),
            Text('nodes >= ${RepCounter.minScore}: $detected/17', style: mono),
            Text('reps ${counter?.reps ?? 0}  phase ${counter?.phaseLabel ?? "-"}', style: mono),
            if (counter?.lastAngle != null)
              Text('angle ${counter!.lastAngle!.toStringAsFixed(0)} deg', style: mono),
            const Divider(height: 10, color: Colors.white24),
            if (kp != null)
              for (var i = 0; i < kp.length; i++)
                Text(
                  '${(counter?.trackedJoints?.contains(i) ?? false) ? ">" : " "}'
                  '${KeypointIndex.names[i].padRight(11)} ${kp[i].score.toStringAsFixed(2)}',
                  style: mono.copyWith(
                    color: kp[i].score >= RepCounter.minScore ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Status line shown under the rep counter in debug mode.
class DebugStatus extends StatelessWidget {
  final String text;
  const DebugStatus(this.text, {super.key});

  @override
  Widget build(BuildContext context) => _PanelBox(
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );
}

/// Nerd mode: everything each workout needs to be counted.
class RequirementsPanel extends StatelessWidget {
  final WorkoutType? highlight;
  final bool dark;
  const RequirementsPanel({super.key, this.highlight, this.dark = true});

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : null;
    final dim = dark ? Colors.white70 : Colors.black54;

    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$label: ', style: TextStyle(color: dim, fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: TextStyle(color: fg)),
          ]), style: const TextStyle(fontSize: 13)),
        );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How counting works', style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'MoveNet finds 17 body points per frame, each with a confidence score. '
          'A joint is only used if its score is at least ${RepCounter.minScore}. '
          'The counter picks the left or right side, whichever is more confident, '
          'and every required joint on that side must pass.',
          style: TextStyle(color: dim, fontSize: 12),
        ),
        for (final type in WorkoutType.values) ...[
          const SizedBox(height: 12),
          Text(
            type.label + (type == highlight ? '  (selected)' : ''),
            style: TextStyle(
              color: type == highlight ? Colors.cyanAccent : fg,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          line('Joints', workoutRules[type]!.joints),
          line('Camera', workoutRules[type]!.camera),
          line('Down phase', workoutRules[type]!.down),
          line('Up phase', workoutRules[type]!.up),
        ],
        const SizedBox(height: 12),
        Text(
          'Tips: good lighting, keep the whole body in frame, wear contrasting clothing, '
          'stay about 2-3 m from the camera, and do full-range reps. Partial reps never '
          'cross the thresholds.',
          style: TextStyle(color: dim, fontSize: 12),
        ),
      ],
    );

    return dark ? _PanelBox(child: content) : content;
  }
}
