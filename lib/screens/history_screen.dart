import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import '../widgets/glass_card.dart';
import 'day_detail_screen.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String describeSession(WorkoutSession s) => '${s.reps} reps x ${s.sets} ${s.type.label}s';

class HistoryScreen extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final ValueChanged<WorkoutSession> onEdit;
  final ValueChanged<WorkoutSession> onDelete;

  const HistoryScreen({
    super.key,
    required this.sessions,
    required this.onEdit,
    required this.onDelete,
  });

  /// Sessions grouped by calendar day, newest day first.
  Map<DateTime, List<WorkoutSession>> _groupByDay() {
    final map = <DateTime, List<WorkoutSession>>{};
    for (final s in sessions) {
      final day = DateTime(s.loggedAt.year, s.loggedAt.month, s.loggedAt.day);
      map.putIfAbsent(day, () => []).add(s);
    }
    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final d in days) d: map[d]!};
  }

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

    final groups = _groupByDay().entries.toList();

    return ListView.separated(
      // Bottom padding keeps the last card clear of the floating nav bar.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final day = groups[index].key;
        final daySessions = groups[index].value;
        return GlassCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DayDetailScreen(
                day: day,
                sessions: daySessions,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatDay(day),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 14),
              for (final s in daySessions)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 8),
                  child: Text(
                    describeSession(s),
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
