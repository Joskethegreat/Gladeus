enum WorkoutType { pushup, pullup, squat }

extension WorkoutTypeLabel on WorkoutType {
  String get label => switch (this) {
    WorkoutType.pushup => 'Push-up',
    WorkoutType.pullup => 'Pull-up',
    WorkoutType.squat => 'Squat',
  };
}

class WorkoutSession {
  final String id;          // e.g. DateTime.now().microsecondsSinceEpoch.toString()
  final WorkoutType type;
  final int sets;
  final int reps;
  final DateTime loggedAt;

  const WorkoutSession({
    required this.id,
    required this.type,
    required this.sets,
    required this.reps,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'sets': sets,
    'reps': reps,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    type: WorkoutType.values.byName(json['type'] as String),
    sets: json['sets'] as int,
    reps: json['reps'] as int,
    loggedAt: DateTime.parse(json['loggedAt'] as String),
  );
}