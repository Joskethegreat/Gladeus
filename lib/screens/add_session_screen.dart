import 'package:flutter/material.dart';

import '../models/workout_session.dart';

class AddSessionScreen extends StatefulWidget {
  /// When provided, the screen edits this session instead of creating a new one.
  final WorkoutSession? initialSession;

  const AddSessionScreen({super.key, this.initialSession});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  WorkoutType? _selectedType;
  late final _setsController = TextEditingController(
    text: widget.initialSession?.sets.toString(),
  );
  late final _repsController = TextEditingController(
    text: widget.initialSession?.reps.toString(),
  );

  bool get _isEditing => widget.initialSession != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSession?.type;
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _submit() {
    final sets = int.tryParse(_setsController.text);
    final reps = int.tryParse(_repsController.text);

    if (_selectedType == null || sets == null || sets <= 0 || reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a type and enter sets/reps greater than 0.')),
      );
      return;
    }

    final session = WorkoutSession(
      id: widget.initialSession?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: _selectedType!,
      sets: sets,
      reps: reps,
      loggedAt: widget.initialSession?.loggedAt ?? DateTime.now(),
    );

    Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Session' : 'Add Session')),
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
            const SizedBox(height: 16),
            TextField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
