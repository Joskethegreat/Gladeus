import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import 'add_session_screen.dart';
import 'camera_log_screen.dart';

class LoggingChoiceScreen extends StatelessWidget {
  const LoggingChoiceScreen({super.key});

  Future<void> _openAndReturn(BuildContext context, Widget screen) async {
    final result = await Navigator.push<WorkoutSession>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (context.mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Workout')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => _openAndReturn(context, const CameraLogScreen()),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openAndReturn(context, const AddSessionScreen()),
              icon: const Icon(Icons.edit),
              label: const Text('Manual'),
            ),
          ],
        ),
      ),
    );
  }
}
