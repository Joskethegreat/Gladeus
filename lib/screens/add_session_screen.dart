import 'package:flutter/material.dart';

import '../models/workout_session.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  WorkoutType? _selectedType;
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();

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
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _selectedType!,
      sets: sets,
      reps: reps,
      loggedAt: DateTime.now(),
    );

    Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Session')),
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
