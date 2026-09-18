import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_session.dart';

class WorkoutRepository {
  static const _sessionsKey = 'workout_sessions';

  Future<List<WorkoutSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSessions(List<WorkoutSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
  }
}
