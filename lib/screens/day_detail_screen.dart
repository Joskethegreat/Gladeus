import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import '../widgets/glass_card.dart';
import 'add_session_screen.dart';
import 'history_screen.dart';
import '../theme/app_colors.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime day;
  final List<WorkoutSession> sessions;
  final ValueChanged<WorkoutSession> onEdit;
  final ValueChanged<WorkoutSession> onDelete;

  const DayDetailScreen({
    super.key,
    required this.day,
    required this.sessions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  // Local copy so this pushed route reflects edits/deletes immediately.
  late List<WorkoutSession> _sessions = List.of(widget.sessions);

  Future<void> _edit(WorkoutSession session) async {
    final updated = await Navigator.push<WorkoutSession>(
      context,
      MaterialPageRoute(builder: (_) => AddSessionScreen(initialSession: session)),
    );
    if (updated == null) return;
    widget.onEdit(updated);
    setState(() {
      _sessions = [for (final s in _sessions) s.id == updated.id ? updated : s];
    });
  }

  Future<void> _confirmDelete(WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text('${describeSession(session)} will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    widget.onDelete(session);
    setState(() => _sessions = _sessions.where((s) => s.id != session.id).toList());
    if (_sessions.isEmpty && mounted) Navigator.pop(context);
  }

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(formatDay(widget.day)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final s = _sessions[i];
          return GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.type.label,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${s.sets} sets × ${s.reps} reps',
                        style: TextStyle(color: c.textSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Logged at ${_time(s.loggedAt)}',
                        style: TextStyle(color: c.textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: c.textSecondary),
                  tooltip: 'Edit',
                  onPressed: () => _edit(s),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(s),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
