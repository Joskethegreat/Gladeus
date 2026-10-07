import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Keypoint {
  final double y;
  final double x;
  final double score;

  const Keypoint(this.y, this.x, this.score);
}

// Standard 17-keypoint order MoveNet outputs.
class KeypointIndex {
  static const nose = 0;
  static const leftShoulder = 5;
  static const rightShoulder = 6;
  static const leftElbow = 7;
  static const rightElbow = 8;
  static const leftWrist = 9;
  static const rightWrist = 10;
  static const leftHip = 11;
  static const rightHip = 12;
  static const leftKnee = 13;
  static const rightKnee = 14;
  static const leftAnkle = 15;
  static const rightAnkle = 16;

  static const names = [
    'nose',
    'L eye',
    'R eye',
    'L ear',
    'R ear',
    'L shoulder',
    'R shoulder',
    'L elbow',
    'R elbow',
    'L wrist',
    'R wrist',
    'L hip',
    'R hip',
    'L knee',
    'R knee',
    'L ankle',
    'R ankle',
  ];

  /// Pairs of keypoint indices to draw as skeleton bones.
  static const bones = [
    [5, 6], [5, 7], [7, 9], [6, 8], [8, 10], //
    [5, 11], [6, 12], [11, 12], //
    [11, 13], [13, 15], [12, 14], [14, 16], //
    [0, 1], [0, 2], [1, 3], [2, 4],
  ];
}

class MoveNetPoseDetector {
  static const inputSize = 192;

  Interpreter? _interpreter;
  TensorType _inputType = TensorType.float32;
  String inputTypeName = '';

  /// The exact 192x192 image fed to the model on the last `detect` call.
  img.Image? lastInput;

  // Flat input buffer reused across frames. Passing raw bytes skips tflite_flutter's
  // slow per-element conversion of a nested 192x192x3 list.
  late Float32List _floatInput;
  late Int32List _int32Input;
  late Uint8List _uint8Input;
  late Uint8List _inputBytes;
  late List<List<List<List<double>>>> _outputBuffer;
  final List<Keypoint> _keypoints = List.filled(17, const Keypoint(0, 0, 0));

  /// Takes the raw model bytes (rather than an asset path) so it can run in a
  /// background isolate, where rootBundle isn't available.
  void load(Uint8List modelBytes) {
    final interpreter = Interpreter.fromBuffer(
      modelBytes,
      options: InterpreterOptions()..threads = 4,
    );
    final type = interpreter.getInputTensor(0).type;
    debugPrint('MoveNet input tensor type: $type');
    _inputType = type;
    inputTypeName = type.toString();
    _interpreter = interpreter;

    const n = inputSize * inputSize * 3;
    _floatInput = Float32List(n);
    _int32Input = Int32List(n);
    _uint8Input = Uint8List(n);
    _inputBytes = switch (type) {
      TensorType.uint8 => _uint8Input,
      TensorType.int32 => _int32Input.buffer.asUint8List(),
      _ => _floatInput.buffer.asUint8List(),
    };
    _outputBuffer = List.generate(
      1,
      (_) => List.generate(1, (_) => List.generate(17, (_) => List.filled(3, 0.0))),
    );
  }

  List<Keypoint> detect(img.Image frame) {
    final resized = img.copyResize(frame, width: inputSize, height: inputSize);
    lastInput = resized;

    // MoveNet expects raw 0-255 channel values for every input type; the float
    // model is NOT normalised to 0-1.
    var i = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        switch (_inputType) {
          case TensorType.uint8:
            _uint8Input[i] = r;
            _uint8Input[i + 1] = g;
            _uint8Input[i + 2] = b;
          case TensorType.int32:
            _int32Input[i] = r;
            _int32Input[i + 1] = g;
            _int32Input[i + 2] = b;
          default:
            _floatInput[i] = r.toDouble();
            _floatInput[i + 1] = g.toDouble();
            _floatInput[i + 2] = b.toDouble();
        }
        i += 3;
      }
    }

    _interpreter!.run(_inputBytes, _outputBuffer);

    for (var k = 0; k < 17; k++) {
      final kp = _outputBuffer[0][0][k];
      _keypoints[k] = Keypoint(kp[0], kp[1], kp[2]);
    }
    return _keypoints;
  }

  void dispose() => _interpreter?.close();
}
