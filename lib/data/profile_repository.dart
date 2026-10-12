import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// Profile storage. The on-device copy always works; when signed in, it is
/// also synced to the `profiles` table in Supabase.
class ProfileRepository {
  static const cacheKey = 'user_profile';
  static const _remoteTimeout = Duration(seconds: 8);

  bool get _canSync => SupabaseService.isConnected && AuthService.currentUser != null;

  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    final local = (raw == null || raw.isEmpty)
        ? const UserProfile()
        : UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (!_canSync) return local;

    try {
      final row = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', AuthService.currentUser!.id)
          .maybeSingle()
          .timeout(_remoteTimeout);
      final remote = row == null ? const UserProfile() : _fromRow(row);

      if (_isEmpty(remote)) {
        // Nothing saved in the cloud yet: upload what is on this device.
        if (!_isEmpty(local)) await _push(local);
        return local;
      }
      await prefs.setString(cacheKey, jsonEncode(remote.toJson()));
      return remote;
    } catch (e) {
      debugPrint('Profile: could not load from Supabase ($e)');
      return local;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(profile.toJson()));
    if (!_canSync) return;
    try {
      await _push(profile);
    } catch (e) {
      debugPrint('Profile: could not save to Supabase ($e)');
    }
  }

  Future<void> _push(UserProfile p) {
    return SupabaseService.client.from('profiles').upsert({
      'id': AuthService.currentUser!.id,
      'name': p.name,
      'gender': p.gender?.name,
      'age': p.age,
      'height_cm': p.heightCm,
      'weight_kg': p.weightKg,
    }).timeout(_remoteTimeout);
  }

  static UserProfile _fromRow(Map<String, dynamic> row) => UserProfile(
    name: (row['name'] as String?) ?? '',
    gender: row['gender'] == null ? null : Gender.values.byName(row['gender'] as String),
    age: row['age'] as int?,
    heightCm: (row['height_cm'] as num?)?.toDouble(),
    weightKg: (row['weight_kg'] as num?)?.toDouble(),
  );

  static bool _isEmpty(UserProfile p) =>
      p.name.isEmpty && p.gender == null && p.age == null && p.heightCm == null && p.weightKg == null;
}
