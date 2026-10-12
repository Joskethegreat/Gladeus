import 'package:shared_preferences/shared_preferences.dart';

import 'profile_repository.dart';
import 'workout_repository.dart';

/// The on-device copy of the signed-in user's data.
class UserDataCache {
  /// Call on log out so the next person to sign in doesn't see this user's data.
  /// App settings (theme, language) are left alone.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ProfileRepository.cacheKey);
    await prefs.remove(WorkoutRepository.cacheKey);
  }
}
