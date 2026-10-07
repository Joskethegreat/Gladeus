import 'dart:math' as math;

import '../models/workout_session.dart';
import 'movenet_pose_detector.dart';

enum _Phase { extended, contracted }

/// Human-readable requirements for a workout, shown in nerd mode. The numeric
/// thresholds here are the same ones the counter uses.
class WorkoutRule {
  final String joints;
  final String camera;
  final String down;
  final String up;
  final double? contractedBelow;
  final double? extendedAbove;

  const WorkoutRule({
    required this.joints,
    required this.camera,
    required this.down,
    required this.up,
    this.contractedBelow,
    this.extendedAbove,
  });
}

const workoutRules = {
  WorkoutType.pushup: WorkoutRule(
    joints: 'Shoulder, elbow and wrist on the same side (left or right).',
    camera: 'Side view, whole upper body in frame, camera roughly at floor/chest height.',
    down: 'Elbow angle drops below 90 deg',
    up: 'Elbow angle rises above 160 deg (rep counts here)',
    contractedBelow: 90,
    extendedAbove: 160,
  ),
  WorkoutType.squat: WorkoutRule(
    joints: 'Hip, knee and ankle on the same side (left or right).',
    camera: 'Side view, full legs in frame from hip to ankle.',
    down: 'Knee angle drops below 100 deg',
    up: 'Knee angle rises above 160 deg (rep counts here)',
    contractedBelow: 100,
    extendedAbove: 160,
  ),
  WorkoutType.pullup: WorkoutRule(
    joints: 'Nose and one wrist (left or right).',
    camera: 'Front or side view, head and hands both visible at the bar.',
    down: 'Nose is at/below wrist height (hanging)',
    up: 'Nose rises above the wrist (rep counts when you lower back down)',
  ),
};

/// Counts reps by tracking a joint angle (or hand/head height for pull-ups)
/// through a full contracted -> extended cycle.
class RepCounter {
  final WorkoutType type;
  _Phase _phase = _Phase.extended;
  int reps = 0;

  RepCounter(this.type);

  static const minScore = 0.3;

  // Debug state, read by the camera screen's debug mode.
  List<int>? trackedJoints;
  double? lastAngle;
  String status = 'Waiting for first frame...';
  String get phaseLabel => _phase == _Phase.extended ? 'extended / up' : 'contracted / down';

  /// Picks whichever side's joints the model is more confident about, or null
  /// if neither side is reliable enough to use this frame.
  List<int>? _bestSide(List<Keypoint> kp, List<int> left, List<int> right) {
    double sum(List<int> s) => s.fold(0.0, (a, i) => a + kp[i].score);
    final side = sum(left) >= sum(right) ? left : right;
    if (side.every((i) => kp[i].score >= minScore)) {
      trackedJoints = side;
      return side;
    }
    trackedJoints = side;
    lastAngle = null;
    final weak = side
        .where((i) => kp[i].score < minScore)
        .map((i) => '${KeypointIndex.names[i]} ${kp[i].score.toStringAsFixed(2)}')
        .join(', ');
    status = 'Not counting: low confidence (< $minScore): $weak';
    return null;
  }

  void update(List<Keypoint> kp) {
    switch (type) {
      case WorkoutType.pushup:
        final s = _bestSide(
          kp,
          [KeypointIndex.leftShoulder, KeypointIndex.leftElbow, KeypointIndex.leftWrist],
          [KeypointIndex.rightShoulder, KeypointIndex.rightElbow, KeypointIndex.rightWrist],
        );
        if (s == null) return;
        _updateByAngle(_angle(kp[s[0]], kp[s[1]], kp[s[2]]),
            contractedBelow: workoutRules[type]!.contractedBelow!,
            extendedAbove: workoutRules[type]!.extendedAbove!);
      case WorkoutType.squat:
        final s = _bestSide(
          kp,
          [KeypointIndex.leftHip, KeypointIndex.leftKnee, KeypointIndex.leftAnkle],
          [KeypointIndex.rightHip, KeypointIndex.rightKnee, KeypointIndex.rightAnkle],
        );
        if (s == null) return;
        _updateByAngle(_angle(kp[s[0]], kp[s[1]], kp[s[2]]),
            contractedBelow: workoutRules[type]!.contractedBelow!,
            extendedAbove: workoutRules[type]!.extendedAbove!);
      case WorkoutType.pullup:
        final s = _bestSide(
          kp,
          [KeypointIndex.nose, KeypointIndex.leftWrist],
          [KeypointIndex.nose, KeypointIndex.rightWrist],
        );
        if (s == null) return;
        _updateByHeight(kp[s[0]], kp[s[1]]);
    }
  }

  void _updateByAngle(
    double angle, {
    required double contractedBelow,
    required double extendedAbove,
  }) {
    lastAngle = angle;
    status = 'Tracking: angle ${angle.toStringAsFixed(0)} deg '
        '(down < ${contractedBelow.toInt()}, up > ${extendedAbove.toInt()})';
    if (_phase == _Phase.extended && angle < contractedBelow) {
      _phase = _Phase.contracted;
    } else if (_phase == _Phase.contracted && angle > extendedAbove) {
      _phase = _Phase.extended;
      reps++;
    }
  }

  void _updateByHeight(Keypoint nose, Keypoint wrist) {
    // Smaller y = higher up in the frame.
    final chinAboveHands = nose.y < wrist.y;
    lastAngle = null;
    status = 'Tracking: nose ${chinAboveHands ? "ABOVE" : "below"} wrist '
        '(nose y ${nose.y.toStringAsFixed(2)}, wrist y ${wrist.y.toStringAsFixed(2)})';
    if (_phase == _Phase.extended && chinAboveHands) {
      _phase = _Phase.contracted;
    } else if (_phase == _Phase.contracted && !chinAboveHands) {
      _phase = _Phase.extended;
      reps++;
    }
  }

  double _angle(Keypoint a, Keypoint b, Keypoint c) {
    final ab = math.atan2(a.y - b.y, a.x - b.x);
    final cb = math.atan2(c.y - b.y, c.x - b.x);
    var angle = (ab - cb).abs() * 180 / math.pi;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }
}
