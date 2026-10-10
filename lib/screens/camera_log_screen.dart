import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/workout_session.dart';
import '../pose/movenet_pose_detector.dart';
import '../pose/pose_debug_widgets.dart';
import '../pose/pose_worker.dart';
import '../pose/rep_counter.dart';
import '../theme/app_colors.dart';
import '../widgets/friendly_dialog.dart';
import '../widgets/slide_to_stop.dart';

enum _Stage { setup, tracking, summary }

const _minReps = 1;
const _accent = Color(0xFFF5A623);

class CameraLogScreen extends StatefulWidget {
  const CameraLogScreen({super.key});

  @override
  State<CameraLogScreen> createState() => _CameraLogScreenState();
}

class _CameraLogScreenState extends State<CameraLogScreen> {
  WorkoutType? _selectedType;
  _Stage _stage = _Stage.setup;
  bool _busy = false;
  String? _error;

  CameraController? _cameraController;
  final PoseWorker _poseWorker = PoseWorker();
  RepCounter? _repCounter;
  bool _processingFrame = false;
  int _sensorOrientation = 0;

  List<CameraDescription> _cameras = [];
  CameraDescription? _currentCamera;
  bool _switchingCamera = false;

  bool _nerdMode = false;
  bool _debugMode = false;
  List<Keypoint>? _latestKeypoints;
  ui.Image? _modelInput;
  ui.Image? _processedFrame;
  String _inputType = '';
  double _fps = 0;
  double _totalMs = 0;
  double _inferMs = 0;
  int _lastFrameMicros = 0;

  @override
  void dispose() {
    final controller = _cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
    controller?.dispose();
    _poseWorker.dispose();
    _modelInput?.dispose();
    _processedFrame?.dispose();
    super.dispose();
  }

  Future<void> _onStartPressed() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _busy = false;
        _error = 'Camera permission denied.';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      _sensorOrientation = camera.sensorOrientation;
      await _poseWorker.start();

      _repCounter = RepCounter(_selectedType!);
      _cameras = cameras;
      _currentCamera = camera;
      _cameraController = controller;
      await controller.startImageStream(_onFrame);

      setState(() {
        _busy = false;
        _stage = _Stage.tracking;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not start camera: $e';
      });
    }
  }

  Future<void> _onSwitchCameraPressed() async {
    if (_switchingCamera || _cameras.length < 2 || _currentCamera == null) return;
    setState(() => _switchingCamera = true);

    final isBack = _currentCamera!.lensDirection == CameraLensDirection.back;
    final target = _cameras.firstWhere(
      (c) => c.lensDirection == (isBack ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _currentCamera!,
    );

    final oldController = _cameraController;
    if (oldController != null && oldController.value.isStreamingImages) {
      await oldController.stopImageStream();
    }
    await oldController?.dispose();

    final controller = CameraController(
      target,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();

    _sensorOrientation = target.sensorOrientation;
    _currentCamera = target;
    _cameraController = controller;
    await controller.startImageStream(_onFrame);

    if (mounted) setState(() => _switchingCamera = false);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processingFrame) return;
    _processingFrame = true;
    try {
      final debug = _debugMode;
      final result = await _poseWorker.detect(image, _sensorOrientation, wantInputImage: debug);
      if (result == null || !mounted) return;
      final counter = _repCounter;
      if (counter == null) return;
      final before = counter.reps;
      counter.update(result.keypoints);

      if (debug) {
        final now = DateTime.now().microsecondsSinceEpoch;
        if (_lastFrameMicros != 0) {
          final instant = 1e6 / (now - _lastFrameMicros);
          _fps = _fps == 0 ? instant : _fps * 0.9 + instant * 0.1;
        }
        _lastFrameMicros = now;
        _latestKeypoints = result.keypoints;
        _inputType = result.inputType;
        _totalMs = result.totalMicros / 1000;
        _inferMs = result.inferMicros / 1000;
        final rgba = result.inputRgba;
        if (rgba != null) {
          ui.decodeImageFromPixels(rgba, 192, 192, ui.PixelFormat.rgba8888, (decoded) {
            if (!mounted) {
              decoded.dispose();
              return;
            }
            setState(() {
              _modelInput?.dispose();
              _modelInput = decoded;
            });
          });
        }
        final processed = result.processedRgba;
        if (processed != null) {
          ui.decodeImageFromPixels(
            processed,
            result.processedWidth,
            result.processedHeight,
            ui.PixelFormat.rgba8888,
            (decoded) {
              if (!mounted) {
                decoded.dispose();
                return;
              }
              setState(() {
                _processedFrame?.dispose();
                _processedFrame = decoded;
              });
            },
          );
        }
        setState(() {});
      } else if (counter.reps != before) {
        setState(() {});
      }
    } catch (e) {
      // Drop a bad frame rather than crash the stream.
      debugPrint('Pose frame failed: $e');
    } finally {
      _processingFrame = false;
    }
  }

  Future<void> _onStopPressed() async {
    final controller = _cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller?.dispose();
    _cameraController = null;

    if (mounted) setState(() => _stage = _Stage.summary);
  }

  void _explainCannotSave() {
    showFriendlyDialog(
      context,
      title: 'No reps counted',
      message: "We didn't spot any reps this time, so there's nothing to save. "
          'Make sure your whole body is in view, then give it another go!',
    );
  }

  void _onSavePressed() {
    final reps = _repCounter?.reps ?? 0;
    if (reps < _minReps) return; // never log a session with zero reps

    final session = WorkoutSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _selectedType!,
      sets: 1,
      reps: reps,
      loggedAt: DateTime.now(),
    );
    Navigator.pop(context, session);
  }

  void _onCancelPressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.setup:
        return _buildSetup();
      case _Stage.tracking:
        return _buildTracking();
      case _Stage.summary:
        return _buildSummary();
    }
  }

  Widget _buildSetup() {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Log')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<WorkoutType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: WorkoutType.values
                  .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nerd mode'),
              subtitle: const Text('Show what each workout needs to be counted'),
              value: _nerdMode,
              onChanged: (v) => setState(() => _nerdMode = v),
            ),
            if (_nerdMode)
              Expanded(
                child: SingleChildScrollView(
                  child: RequirementsPanel(highlight: _selectedType, dark: false),
                ),
              )
            else
              const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: (_selectedType == null || _busy) ? null : _onStartPressed,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracking() {
    final controller = _cameraController!;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          if (_debugMode && _latestKeypoints != null)
            IgnorePointer(
              child: CustomPaint(
                painter: SkeletonPainter(
                  _latestKeypoints!,
                  tracked: _repCounter?.trackedJoints ?? const [],
                  mirrorX: _currentCamera?.lensDirection == CameraLensDirection.front,
                  labels: true,
                ),
              ),
            ),
          if (_debugMode)
            Positioned(
              top: 104,
              left: 8,
              child: DebugPanel(
                modelInput: _modelInput,
                processedFrame: _processedFrame,
                keypoints: _latestKeypoints,
                counter: _repCounter,
                inputType: _inputType,
                fps: _fps,
                totalMs: _totalMs,
                inferMs: _inferMs,
              ),
            ),
          if (_debugMode)
            Positioned(
              bottom: 112,
              left: 8,
              right: 8,
              child: Center(child: DebugStatus(_repCounter?.status ?? '')),
            ),
          if (_nerdMode)
            Positioned(
              top: 104,
              left: 8,
              right: 8,
              bottom: 112,
              child: SingleChildScrollView(
                child: RequirementsPanel(highlight: _selectedType),
              ),
            ),
          Positioned(
            top: 48,
            left: 8,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Debug mode',
                  onPressed: () => setState(() {
                    _debugMode = !_debugMode;
                    _fps = 0;
                    _lastFrameMicros = 0;
                  }),
                  icon: Icon(Icons.bug_report,
                      color: _debugMode ? Colors.cyanAccent : Colors.white, size: 30),
                ),
                IconButton(
                  tooltip: 'Nerd mode',
                  onPressed: () => setState(() => _nerdMode = !_nerdMode),
                  icon: Icon(Icons.menu_book,
                      color: _nerdMode ? Colors.cyanAccent : Colors.white, size: 30),
                ),
              ],
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: IconButton(
              onPressed: (_cameras.length < 2 || _switchingCamera) ? null : _onSwitchCameraPressed,
              icon: _switchingCamera
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
            ),
          ),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Reps: ${_repCounter?.reps ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: SlideToStop(onComplete: _onStopPressed),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final c = context.colors;
    final reps = _repCounter?.reps ?? 0;
    final canSave = reps >= _minReps;
    final noun = _selectedType!.label.toLowerCase();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        canSave ? 'Amazing!' : 'No reps counted',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$reps',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 120,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -4,
                          height: 1.05,
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'reps of ${noun}s',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.textSecondary, fontSize: 20, letterSpacing: -0.2),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // Stays tappable when unavailable so it can explain why.
                  onPressed: canSave ? _onSavePressed : _explainCannotSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: canSave ? _accent : c.divider,
                    foregroundColor: canSave ? Colors.black87 : c.textTertiary,
                    minimumSize: const Size.fromHeight(54),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _onCancelPressed,
                style: TextButton.styleFrom(
                  foregroundColor: c.textTertiary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
