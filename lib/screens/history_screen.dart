import 'package:flutter/material.dart';

import '../models/workout_session.dart';

class HistoryScreen extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const HistoryScreen({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'No sessions yet',
          style: TextStyle(color: Colors.white70, fontSize: 20),
        ),
      );
    }

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return ListTile(
          leading: const Icon(Icons.fitness_center),
          title: Text('${session.type.label} · ${session.sets} sets × ${session.reps} reps'),
          subtitle: Text(session.loggedAt.toString()),
        );
      },
    );
  }
}
