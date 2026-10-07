import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'movenet_pose_detector.dart';

/// One frame's worth of output from the worker.
class PoseResult {
  final List<Keypoint> keypoints;

  /// The 192x192 RGBA image the model actually saw (only when requested).
  final Uint8List? inputRgba;

  /// The frame after conversion + rotation, before the squash to 192x192.
  final Uint8List? processedRgba;
  final int processedWidth;
  final int processedHeight;
  final int totalMicros;
  final int inferMicros;
  final String inputType;

  PoseResult(
    this.keypoints,
    this.inputRgba,
    this.processedRgba,
    this.processedWidth,
    this.processedHeight,
    this.totalMicros,
    this.inferMicros,
    this.inputType,
  );
}

/// Runs frame conversion + MoveNet inference on a background isolate so the
/// UI isolate only pays for copying plane bytes and receiving keypoints.
class PoseWorker {
  Isolate? _isolate;
  SendPort? _send;
  ReceivePort? _receive;
  StreamSubscription? _sub;
  Completer<PoseResult?>? _pending;

  Future<void> start() async {
    final modelBytes =
        (await rootBundle.load('assets/models/movenet_lightning.tflite')).buffer.asUint8List();

    final receive = ReceivePort();
    _receive = receive;
    final ready = Completer<void>();
    _sub = receive.listen((msg) {
      if (msg is SendPort) {
        _send = msg;
        ready.complete();
      } else if (msg is String) {
        // Load failure inside the isolate.
        if (!ready.isCompleted) ready.completeError(msg);
      } else if (msg == null || msg is _ResultMsg) {
        final pending = _pending;
        _pending = null;
        pending?.complete(msg == null ? null : _decode(msg as _ResultMsg));
      }
    });

    _isolate = await Isolate.spawn(_entry, _InitMsg(receive.sendPort, modelBytes));
    await ready.future;
  }

  /// Returns the result for the frame, or null if the frame failed.
  /// [wantInputImage] also returns the exact image the model saw (debug mode).
  Future<PoseResult?> detect(CameraImage image, int rotation, {bool wantInputImage = false}) {
    final pending = Completer<PoseResult?>();
    _pending = pending;
    _send!.send(_FrameMsg(
      isBgra: image.format.group == ImageFormatGroup.bgra8888,
      width: image.width,
      height: image.height,
      rotation: rotation,
      wantInputImage: wantInputImage,
      planes: [
        for (final p in image.planes) TransferableTypedData.fromList([p.bytes]),
      ],
      bytesPerRow: [for (final p in image.planes) p.bytesPerRow],
      bytesPerPixel: [for (final p in image.planes) p.bytesPerPixel ?? 1],
    ));
    return pending.future;
  }

  void dispose() {
    _sub?.cancel();
    _receive?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(null);
  }

  static PoseResult _decode(_ResultMsg m) => PoseResult(
        [
          for (var i = 0; i < 17; i++)
            Keypoint(m.flat[i * 3], m.flat[i * 3 + 1], m.flat[i * 3 + 2]),
        ],
        m.rgba,
        m.processedRgba,
        m.processedWidth,
        m.processedHeight,
        m.totalMicros,
        m.inferMicros,
        m.inputType,
      );
}

class _InitMsg {
  final SendPort reply;
  final Uint8List modelBytes;
  _InitMsg(this.reply, this.modelBytes);
}

class _ResultMsg {
  final Float64List flat;
  final Uint8List? rgba;
  final Uint8List? processedRgba;
  final int processedWidth;
  final int processedHeight;
  final int totalMicros;
  final int inferMicros;
  final String inputType;
  _ResultMsg(
    this.flat,
    this.rgba,
    this.processedRgba,
    this.processedWidth,
    this.processedHeight,
    this.totalMicros,
    this.inferMicros,
    this.inputType,
  );
}

class _FrameMsg {
  final bool isBgra;
  final bool wantInputImage;
  final int width;
  final int height;
  final int rotation;
  final List<TransferableTypedData> planes;
  final List<int> bytesPerRow;
  final List<int> bytesPerPixel;

  _FrameMsg({
    required this.isBgra,
    required this.wantInputImage,
    required this.width,
    required this.height,
    required this.rotation,
    required this.planes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });
}

void _entry(_InitMsg init) {
  final detector = MoveNetPoseDetector();
  try {
    detector.load(init.modelBytes);
  } catch (e) {
    init.reply.send('Model load failed: $e');
    return;
  }

  final port = ReceivePort();
  init.reply.send(port.sendPort);

  port.listen((msg) {
    if (msg is! _FrameMsg) return;
    try {
      final total = Stopwatch()..start();
      var frame = _convert(msg);
      // Android delivers frames in sensor orientation; rotate upright for the model.
      if (msg.rotation != 0) {
        frame = img.copyRotate(frame, angle: msg.rotation);
      }
      final infer = Stopwatch()..start();
      final kp = detector.detect(frame);
      infer.stop();
      final flat = Float64List(51);
      for (var i = 0; i < 17; i++) {
        flat[i * 3] = kp[i].y;
        flat[i * 3 + 1] = kp[i].x;
        flat[i * 3 + 2] = kp[i].score;
      }
      Uint8List? rgba;
      Uint8List? processedRgba;
      if (msg.wantInputImage) {
        final seen = detector.lastInput;
        if (seen != null) rgba = _toRgba(seen);
        processedRgba = _toRgba(frame);
      }
      total.stop();
      init.reply.send(_ResultMsg(
        flat,
        rgba,
        processedRgba,
        frame.width,
        frame.height,
        total.elapsedMicroseconds,
        infer.elapsedMicroseconds,
        detector.inputTypeName,
      ));
    } catch (_) {
      init.reply.send(null);
    }
  });
}

Uint8List _toRgba(img.Image image) {
  final out = Uint8List(image.width * image.height * 4);
  var o = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      out[o++] = p.r.toInt();
      out[o++] = p.g.toInt();
      out[o++] = p.b.toInt();
      out[o++] = 255;
    }
  }
  return out;
}

// The model only needs a ~192px frame, so there's no point paying for a
// full-resolution YUV/BGRA->RGB conversion just to immediately downscale it.
// Sample every `stride`-th pixel straight into the small output image instead.
img.Image _convert(_FrameMsg m) {
  final planes = [for (final p in m.planes) p.materialize().asUint8List()];
  final shortSide = m.width < m.height ? m.width : m.height;
  final stride = (shortSide / 192).floor().clamp(1, 8);
  return m.isBgra ? _convertBGRA8888(m, planes, stride) : _convertYUV420(m, planes, stride);
}

img.Image _convertBGRA8888(_FrameMsg m, List<Uint8List> planes, int stride) {
  final bytes = planes[0];
  final bytesPerRow = m.bytesPerRow[0];
  final outWidth = m.width ~/ stride;
  final outHeight = m.height ~/ stride;
  final out = img.Image(width: outWidth, height: outHeight);

  for (int oy = 0; oy < outHeight; oy++) {
    final rowOffset = (oy * stride) * bytesPerRow;
    for (int ox = 0; ox < outWidth; ox++) {
      final i = rowOffset + (ox * stride) * 4;
      out.setPixelRgb(ox, oy, bytes[i + 2], bytes[i + 1], bytes[i]);
    }
  }
  return out;
}

img.Image _convertYUV420(_FrameMsg m, List<Uint8List> planes, int stride) {
  final yBytes = planes[0];
  final uBytes = planes[1];
  final vBytes = planes[2];
  final uvPixelStride = m.bytesPerPixel[1];
  final outWidth = m.width ~/ stride;
  final outHeight = m.height ~/ stride;
  final out = img.Image(width: outWidth, height: outHeight);

  for (int oy = 0; oy < outHeight; oy++) {
    final y = oy * stride;
    final yRowOffset = y * m.bytesPerRow[0];
    final uvRow = y ~/ 2;
    final uRowOffset = uvRow * m.bytesPerRow[1];
    final vRowOffset = uvRow * m.bytesPerRow[2];
    for (int ox = 0; ox < outWidth; ox++) {
      final x = ox * stride;
      final yIndex = yRowOffset + x;
      final uvCol = x ~/ 2;
      final uIndex = uRowOffset + uvCol * uvPixelStride;
      final vIndex = vRowOffset + uvCol * uvPixelStride;

      final yVal = yBytes[yIndex];
      final uVal = uBytes[uIndex];
      final vVal = vBytes[vIndex];

      final r = (yVal + 1.402 * (vVal - 128)).clamp(0, 255).toInt();
      final g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128)).clamp(0, 255).toInt();
      final b = (yVal + 1.772 * (uVal - 128)).clamp(0, 255).toInt();

      out.setPixelRgb(ox, oy, r, g, b);
    }
  }
  return out;
}
