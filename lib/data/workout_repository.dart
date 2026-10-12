import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_session.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// Workout storage. The on-device copy always works; when signed in, it is
/// also synced to the `workout_sessions` table in Supabase.
class WorkoutRepository {
  static const cacheKey = 'workout_sessions';
  static const _table = 'workout_sessions';
  static const _remoteTimeout = Duration(seconds: 8);

  bool get _canSync => SupabaseService.isConnected && AuthService.currentUser != null;

  Future<List<WorkoutSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final local = _decodeLocal(prefs.getString(cacheKey));
    if (!_canSync) return local;

    try {
      final rows = await SupabaseService.client
          .from(_table)
          .select()
          .order('logged_at', ascending: false)
          .timeout(_remoteTimeout);
      final remote = [for (final r in rows) _fromRow(r)];

      // Anything only on this device (e.g. logged before the first sign in)
      // is uploaded, then both sides are merged. The cloud copy wins on clashes.
      final remoteIds = {for (final s in remote) s.id};
      final localOnly = local.where((s) => !remoteIds.contains(s.id)).toList();
      if (localOnly.isNotEmpty) await _upsert(localOnly);

      final merged = [...remote, ...localOnly]
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      await prefs.setString(cacheKey, _encode(merged));
      return merged;
    } catch (e) {
      debugPrint('Workouts: could not load from Supabase ($e)');
      return local;
    }
  }

  Future<void> saveSessions(List<WorkoutSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final before = _decodeLocal(prefs.getString(cacheKey));
    await prefs.setString(cacheKey, _encode(sessions));
    if (!_canSync) return;

    // Only send what changed since the last save.
    final beforeById = {for (final s in before) s.id: jsonEncode(s.toJson())};
    final nowIds = {for (final s in sessions) s.id};
    final changed = sessions.where((s) => beforeById[s.id] != jsonEncode(s.toJson())).toList();
    final removedIds = beforeById.keys.where((id) => !nowIds.contains(id)).toList();

    try {
      if (changed.isNotEmpty) await _upsert(changed);
      if (removedIds.isNotEmpty) {
        await SupabaseService.client
            .from(_table)
            .delete()
            .inFilter('id', removedIds)
            .timeout(_remoteTimeout);
      }
    } catch (e) {
      debugPrint('Workouts: could not save to Supabase ($e)');
    }
  }

  Future<void> _upsert(List<WorkoutSession> sessions) {
    return SupabaseService.client
        .from(_table)
        .upsert([for (final s in sessions) _toRow(s)], onConflict: 'user_id,id')
        .timeout(_remoteTimeout);
  }

  static Map<String, dynamic> _toRow(WorkoutSession s) => {
    'id': s.id,
    'type': s.type.name,
    'sets': s.sets,
    'reps': s.reps,
    'logged_at': s.loggedAt.toUtc().toIso8601String(),
  };

  static WorkoutSession _fromRow(Map<String, dynamic> row) => WorkoutSession(
    id: row['id'] as String,
    type: WorkoutType.values.byName(row['type'] as String),
    sets: row['sets'] as int,
    reps: row['reps'] as int,
    loggedAt: DateTime.parse(row['logged_at'] as String).toLocal(),
  );

  static List<WorkoutSession> _decodeLocal(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String _encode(List<WorkoutSession> sessions) =>
      jsonEncode(sessions.map((s) => s.toJson()).toList());
}
